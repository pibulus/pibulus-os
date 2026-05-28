# Costs

Cost is not the scary part here.

As of the last check, Bunny Standard CDN pricing was roughly:

- North America / Europe: `$0.01/GB`
- Asia / Oceania: `$0.03/GB`

Melbourne traffic probably means using the `$0.03/GB` number for rough thinking.

Re-check before relying on it:

```text
https://bunny.net/pricing/cdn/
```

## Rough Feel

Static site assets are tiny:

```text
10,000 people * 2 MB = 20 GB
20 GB * $0.03 = $0.60
```

Radio at 128 kbps:

```text
50 listeners * 4 hours/day * 30 days = about 230 GB
230 GB * $0.03 = about $7/month
```

Video is the only thing that gets chunky:

```text
5 people * 1080p 8 Mbps * 2 hours/day * 30 days = about 1 TB
1 TB * $0.03 = about $30/month
```

Still not terrifying, just not the first thing to proxy because Jellyfin is
weirder than it is expensive.

## Guardrail

Turn on Bunny bandwidth / overage protection anyway.

Not because we are budgeting like a corporation. Just because it is silly to
leave an avoidable footgun lying around.

## Takeaway

Use Bunny where it makes the Pi calmer.

If a path costs a few bucks and removes repeated traffic from the desk Pi, great.
If it makes debugging annoying, delete it.
