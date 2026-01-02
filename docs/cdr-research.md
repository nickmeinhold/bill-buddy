# CDR Research & Business Model

Research notes on Australia's Consumer Data Right framework and the opportunity for a Rocket Money-style app.

## The Opportunity

Australia is ripe for a Rocket Money equivalent:
- Australian households spend $50/month on streaming alone (up 16% YoY)
- 46% of users actively rotate between services to manage costs
- 39% plan to cancel at least one subscription in the next 12 months
- 3 in 10 Australians lose up to $600/year on duplicate/unused services

**The gap**: No Australian competitor offers Rocket Money's full feature set. Frollo, WeMoney, PocketSmith focus on budgeting—none offer bill negotiation or automated subscription cancellation.

## CDR Data Flow

See [cdr-data-flow.mermaid](./cdr-data-flow.mermaid) for a sequence diagram of how data flows between consumers, apps, ADRs, and banks.

## Regulatory Paths

| Approach | Upfront Cost | Ongoing Cost | Time to Market |
|----------|-------------|--------------|----------------|
| Full ADR (outsourced) | $150-300k | $50-100k/yr | 6-12+ months |
| Full ADR (DIY technical) | $30-80k | $30-50k/yr | 6-12+ months |
| CDR Representative | $10-30k | Fees to principal | 2-4 months |
| Use intermediary (Basiq) | $0-5k | $0.50-2/user/mo | Weeks |

### Unavoidable Costs (even for technical founders)
- AFCA membership: ~$2,500-5,000/year
- Insurance (PI + Cyber): $10,000-30,000/year
- Independent security assessment: $15,000-30,000

## Business Model Options

### Option A: Subscription + Success Fee (Rocket Money model)
- Free tier: See subscriptions, get alerts
- Premium ($8/month): Cancellation concierge, bill monitoring
- Negotiation: 40% of first year savings

### Option B: Pure Affiliate
- Free app, revenue from switches
- Energy switch: $50-200 per switch
- Internet switch: $50-100 per switch
- Insurance referral: $30-150 per policy

### Option C: Hybrid (Recommended)
- Free: Subscription tracking, bill comparison
- Premium ($6/month): Cancellation service, priority support
- Negotiation: 35% of savings OR flat $25 per successful negotiation
- Switches: Affiliate commission (don't charge user)

## Key Research Links

- [Basiq API Docs](https://api.basiq.io/docs/guides) - CDR-accredited intermediary
- [CDR Sandbox](https://cdrsandbox.gov.au/) - Government testing environment
- [Consumer Data Standards](https://consumerdatastandardsaustralia.github.io/) - Technical specs
- [Data Holder API Database](https://github.com/LukePrior/Australian-Open-Banking-Data-Database) - All bank endpoints

## Competitors / Landscape

| App | Consumer Cost | Revenue Model |
|-----|--------------|---------------|
| Frollo | Free | B2B white-label, data services |
| WeMoney | Free | Freemium, affiliate fees |
| Raiz | $4.50/month | Subscription + management fees |
| Basiq | N/A (B2B) | Per-user API fees |
| Banks (Westpac etc.) | Free | Customer retention |
