import { Plugin } from "@opencode/plugin/tui"
import { execFile } from "node:child_process"
import { promisify } from "node:util"

const run = promisify(execFile)

export default Plugin.define({
  id: "copilot-quota",
  setup(context) {
    return context.data.on("session.execution.succeeded", async () => {
      try {
        const { stdout } = await run("gh", ["api", "/copilot_internal/user"], { timeout: 10_000 })
        const data = JSON.parse(stdout)
        const premium = data?.quota_snapshots?.premium_interactions

        if (!premium || !premium.has_quota) return

        const entitlement: number = premium.entitlement
        const remaining: number = Math.floor(premium.quota_remaining)
        const used: number = entitlement - remaining
        const pctUsed: number = parseFloat((100 - premium.percent_remaining).toFixed(1))
        const resetDate: string = data.quota_reset_date

        context.ui.toast.show({
          message: `${used}/${entitlement} used (${pctUsed}%) — ${resetDate}`,
          variant: "info",
        })
      } catch {
        // gh not available or quota fetch failed — silently skip
      }
    })
  },
})
