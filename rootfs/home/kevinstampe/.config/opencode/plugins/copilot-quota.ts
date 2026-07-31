import type { Plugin } from "@opencode-ai/plugin"

export const CopilotQuotaPlugin: Plugin = async ({ client, $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        try {
          const output = await $`gh api /copilot_internal/user`.text()
          const data = JSON.parse(output)
          const premium = data?.quota_snapshots?.premium_interactions

          if (!premium || !premium.has_quota) return

          const entitlement: number = premium.entitlement
          const remaining: number = Math.floor(premium.quota_remaining)
          const used: number = entitlement - remaining
          const pctUsed: number = parseFloat((100 - premium.percent_remaining).toFixed(1))
          const resetDate: string = data.quota_reset_date

          await client.tui.showToast({
            body: {
              message: `${used}/${entitlement} used (${pctUsed}%) — ${resetDate}`,
              variant: "info",
            },
          })
        } catch {
          // gh not available or quota fetch failed — silently skip
        }
      }
    },
  }
}
