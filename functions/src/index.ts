import { onObjectFinalized } from "firebase-functions/v2/storage";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { PDFParse } from "pdf-parse";

initializeApp();

const db = getFirestore();
const storage = getStorage();

interface ParsedTransaction {
  date: Date;
  merchantName: string;
  amount: number;
  category: string;
}

/**
 * Cloud Function triggered when a PDF is uploaded to Firebase Storage.
 * Parses the PDF to extract transactions and stores them in Firestore.
 */
export const parseStatement = onObjectFinalized(
  {
    bucket: "bill-buddy-93c8a.firebasestorage.app",
    region: "australia-southeast1",
  },
  async (event) => {
  const filePath = event.data.name;
  const contentType = event.data.contentType;

  // Only process PDF files in the statements folder
  if (!filePath || !contentType?.includes("pdf")) {
    console.log("Not a PDF file, skipping");
    return;
  }

  // Expected path: users/{userId}/statements/{filename}
  const pathParts = filePath.split("/");
  if (pathParts.length !== 4 || pathParts[0] !== "users" || pathParts[2] !== "statements") {
    console.log("Not a statement file, skipping:", filePath);
    return;
  }

  const userId = pathParts[1];
  const fileName = pathParts[3];

  console.log(`Processing statement for user ${userId}: ${fileName}`);

  // Find the statement document by storagePath
  const statementsRef = db.collection("users").doc(userId).collection("statements");
  const querySnapshot = await statementsRef
    .where("storagePath", "==", filePath)
    .limit(1)
    .get();

  if (querySnapshot.empty) {
    console.error("No statement document found for:", filePath);
    return;
  }

  const statementDoc = querySnapshot.docs[0];
  const statementId = statementDoc.id;

  try {
    // Download the PDF from Storage
    const bucket = storage.bucket(event.data.bucket);
    const file = bucket.file(filePath);
    const [buffer] = await file.download();

    // Parse the PDF
    const parser = new PDFParse({ data: buffer });
    const pdfData = await parser.getText();
    const text = pdfData.text;
    await parser.destroy();

    console.log("Extracted PDF text length:", text.length);

    // Parse transactions from the text
    const transactions = parseTransactionsFromText(text);

    console.log(`Found ${transactions.length} transactions`);

    // Write transactions to Firestore
    const transactionsRef = db.collection("users").doc(userId).collection("transactions");
    const batch = db.batch();

    for (const tx of transactions) {
      const docRef = transactionsRef.doc();
      batch.set(docRef, {
        merchantName: tx.merchantName,
        amount: tx.amount,
        date: tx.date.toISOString(),
        category: tx.category,
        isSubscription: false,
        notes: null,
        accountId: null,
        statementId: statementId,
      });
    }

    await batch.commit();

    // Update statement status to completed
    await statementDoc.ref.update({
      status: "completed",
      transactionCount: transactions.length,
    });

    console.log(`Successfully processed ${transactions.length} transactions for statement ${statementId}`);
  } catch (error) {
    console.error("Error processing statement:", error);

    // Update statement status to failed
    await statementDoc.ref.update({
      status: "failed",
      errorMessage: error instanceof Error ? error.message : "Unknown error occurred",
    });
  }
  }
);

/**
 * Parses transaction data from extracted PDF text.
 * Supports Commonwealth Bank (Australia) format:
 * - Date: "DD Mmm" (e.g., "09 Aug")
 * - Multi-line descriptions
 * - Separate Debit/Credit columns
 */
function parseTransactionsFromText(text: string): ParsedTransaction[] {
  const transactions: ParsedTransaction[] = [];
  const lines = text.split("\n");

  // Australian bank date pattern: DD Mmm (e.g., "09 Aug", "15 Sep")
  const ausDatePattern = /^(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b/i;
  // US date patterns: MM/DD/YYYY, MM-DD-YYYY
  const usDatePattern = /^(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})/;

  // Amount patterns
  // $200.00 or $1,200.00 (credit - before description)
  // 200.00 $ or 1,200.00 $ (debit - amount then $)
  const amountPattern = /\$[\d,]+\.\d{2}|[\d,]+\.\d{2}\s*\$/g;

  let currentYear = new Date().getFullYear();
  let i = 0;

  while (i < lines.length) {
    const line = lines[i].trim();

    // Try Australian date format first
    let ausMatch = line.match(ausDatePattern);
    let usMatch = line.match(usDatePattern);

    if (ausMatch) {
      // Commonwealth Bank format
      const day = parseInt(ausMatch[1], 10);
      const monthStr = ausMatch[2];
      const date = parseAusDate(day, monthStr, currentYear);

      if (date) {
        // Collect the full transaction (may span multiple lines)
        let fullText = line;
        let j = i + 1;

        // Keep adding lines until we hit another date or empty line
        while (j < lines.length) {
          const nextLine = lines[j].trim();
          if (!nextLine || ausDatePattern.test(nextLine) || usDatePattern.test(nextLine)) {
            break;
          }
          fullText += " " + nextLine;
          j++;
        }

        // Extract amounts from the full text
        const amounts = fullText.match(amountPattern);

        if (amounts && amounts.length > 0) {
          // Determine if debit or credit based on format
          // Debit: "200.00 $" (amount before $)
          // Credit: "$200.00" ($ before amount)
          let amount = 0;
          let isDebit = false;

          for (const amtStr of amounts) {
            // Skip balance column (usually the last/largest amount with CR)
            if (fullText.includes(amtStr) && fullText.indexOf(amtStr) < fullText.lastIndexOf("CR")) {
              const parsed = parseAmount(amtStr);
              if (parsed !== 0) {
                // Check if it's debit format (number then $)
                isDebit = /[\d,]+\.\d{2}\s*\$/.test(amtStr);
                amount = isDebit ? -Math.abs(parsed) : Math.abs(parsed);
                break; // Use first non-balance amount
              }
            }
          }

          // If no amount found before CR, try all amounts
          if (amount === 0 && amounts.length > 0) {
            const firstAmt = amounts[0];
            const parsed = parseAmount(firstAmt);
            isDebit = /[\d,]+\.\d{2}\s*\$/.test(firstAmt);
            amount = isDebit ? -Math.abs(parsed) : Math.abs(parsed);
          }

          if (amount !== 0) {
            // Extract description (text after date, before amounts)
            let description = fullText
              .replace(ausDatePattern, "")
              .replace(amountPattern, "")
              .replace(/\d+\.\d{2}/g, "") // Remove any remaining decimals
              .replace(/CR\s*$/i, "")
              .replace(/\s+/g, " ")
              .trim();

            // Clean up common prefixes
            description = description
              .replace(/^(Fast Transfer From|Transfer To|Direct Credit|Wdl ATM|Non CBA)\s*/i, "")
              .trim();

            if (!description || description.length < 2) {
              description = "Unknown Transaction";
            }

            const category = categorizeTransaction(description);

            transactions.push({
              date,
              merchantName: description.substring(0, 100), // Limit length
              amount,
              category,
            });
          }
        }

        i = j; // Skip to next unprocessed line
        continue;
      }
    } else if (usMatch) {
      // US format - original logic
      const dateStr = usMatch[1];
      const date = parseDate(dateStr);

      if (date) {
        const amounts = line.match(amountPattern);
        if (amounts && amounts.length > 0) {
          const amountStr = amounts[0];
          const amount = parseAmount(amountStr);

          if (amount !== 0) {
            let merchantName = line
              .replace(usDatePattern, "")
              .replace(amountPattern, "")
              .replace(/\s+/g, " ")
              .trim();

            if (!merchantName || merchantName.length < 2) {
              merchantName = "Unknown Transaction";
            }

            const category = categorizeTransaction(merchantName);
            transactions.push({ date, merchantName, amount, category });
          }
        }
      }
    }

    i++;
  }

  return transactions;
}

function parseAusDate(day: number, monthStr: string, year: number): Date | null {
  const months: Record<string, number> = {
    jan: 0, feb: 1, mar: 2, apr: 3, may: 4, jun: 5,
    jul: 6, aug: 7, sep: 8, oct: 9, nov: 10, dec: 11,
  };

  const month = months[monthStr.toLowerCase()];
  if (month === undefined) return null;
  if (day < 1 || day > 31) return null;

  return new Date(year, month, day);
}

function parseAmount(amountStr: string): number {
  // Remove currency symbol and commas
  let cleaned = amountStr.replace(/[$,]/g, "");

  // Handle parentheses for negative amounts: (123.45) -> -123.45
  if (cleaned.startsWith("(") && cleaned.endsWith(")")) {
    cleaned = "-" + cleaned.slice(1, -1);
  }

  const amount = parseFloat(cleaned);
  return isNaN(amount) ? 0 : amount;
}

function parseDate(dateStr: string): Date | null {
  // Try different date formats
  const parts = dateStr.split(/[/-]/);
  if (parts.length !== 3) return null;

  // Assume MM/DD/YYYY format (common in US)
  const month = parseInt(parts[0], 10);
  const day = parseInt(parts[1], 10);
  let year = parseInt(parts[2], 10);

  // Handle 2-digit years
  if (year < 100) {
    year += year > 50 ? 1900 : 2000;
  }

  // Validate
  if (month < 1 || month > 12) return null;
  if (day < 1 || day > 31) return null;
  if (year < 1900 || year > 2100) return null;

  return new Date(year, month - 1, day);
}

function categorizeTransaction(merchantName: string): string {
  const name = merchantName.toLowerCase();

  // Food & Dining
  if (
    name.includes("restaurant") ||
    name.includes("cafe") ||
    name.includes("coffee") ||
    name.includes("starbucks") ||
    name.includes("mcdonald") ||
    name.includes("pizza") ||
    name.includes("food") ||
    name.includes("doordash") ||
    name.includes("uber eats") ||
    name.includes("grubhub")
  ) {
    return "Food & Dining";
  }

  // Shopping
  if (
    name.includes("amazon") ||
    name.includes("walmart") ||
    name.includes("target") ||
    name.includes("costco") ||
    name.includes("store") ||
    name.includes("shop")
  ) {
    return "Shopping";
  }

  // Transportation
  if (
    name.includes("uber") ||
    name.includes("lyft") ||
    name.includes("gas") ||
    name.includes("shell") ||
    name.includes("chevron") ||
    name.includes("exxon") ||
    name.includes("parking")
  ) {
    return "Transportation";
  }

  // Entertainment
  if (
    name.includes("netflix") ||
    name.includes("spotify") ||
    name.includes("hulu") ||
    name.includes("disney") ||
    name.includes("movie") ||
    name.includes("theater") ||
    name.includes("gaming")
  ) {
    return "Entertainment";
  }

  // Utilities
  if (
    name.includes("electric") ||
    name.includes("water") ||
    name.includes("gas") ||
    name.includes("utility") ||
    name.includes("internet") ||
    name.includes("phone") ||
    name.includes("verizon") ||
    name.includes("at&t") ||
    name.includes("t-mobile")
  ) {
    return "Utilities";
  }

  // Healthcare
  if (
    name.includes("pharmacy") ||
    name.includes("cvs") ||
    name.includes("walgreens") ||
    name.includes("doctor") ||
    name.includes("hospital") ||
    name.includes("medical") ||
    name.includes("health")
  ) {
    return "Healthcare";
  }

  // Groceries
  if (
    name.includes("grocery") ||
    name.includes("safeway") ||
    name.includes("kroger") ||
    name.includes("whole foods") ||
    name.includes("trader joe")
  ) {
    return "Groceries";
  }

  return "Other";
}
