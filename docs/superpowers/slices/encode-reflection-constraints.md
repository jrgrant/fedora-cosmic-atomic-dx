---
task: "Encode the three unaddressed constraints from REFLECTION_LOG.md into HARNESS.md: local build gate, ujust recipe collision check, research adversarial review gate"
task_slug: encode-reflection-constraints
date: 2026-08-02
carpaccio_model: DeepSeek V4 Pro
inseparable: false
progressed_slice: S3
slices:
  - id: S1
    title: "Local build gate — enforcement type decision"
    scope: "Add the Containerfile local-build-gate constraint entry to HARNESS.md. The constraint text is settled ('Containerfile build must pass locally before CI is re-enabled') but the enforcement type is not: the human must decide between unverified (documented expectation), deterministic (a pre-push hook or local script), or agent (harness-enforcer checks PRs for build evidence). The scope includes writing the constraint entry in the existing HARNESS.md format once the enforcement decision is made."
    decision_focus: "What enforcement type should the local build gate carry?"
    lens_used: decision-boundary
    disposition: accepted
    disposition_rationale: "Unverified enforcement. CI already catches build failures at PR time. A local pre-push hook adds friction without clear benefit until the project has hook infrastructure. Mark unverified, revisit when hook tooling exists."
    file_as_issue: true
    issue_url: https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/40
    merged_into: null
    sequencing_note: "Independent of S2 and S3. Only touches HARNESS.md."
  - id: S2
    title: "ujust recipe collision CI check"
    scope: "Write a deterministic CI check that extracts recipe names from system_files/shared/usr/share/ublue-os/just/60-custom.just, diffs them against upstream recipe names from the bluefin submodule, and fails CI on any collision. Add the corresponding constraint entry to HARNESS.md. Integrate into .github/workflows/build.yml."
    decision_focus: "Confirm enforcement type (deterministic), tool placement (standalone script vs extension of ai-literacy-check.sh), and scope (commit vs pr)."
    lens_used: acceptance-criterion
    disposition: accepted
    disposition_rationale: "Documented silent breakage from reflection. Standalone script at scripts/check-recipe-collisions.sh, CI step (pr scope — needs bluefin submodule). Deterministic enforcement."
    file_as_issue: true
    issue_url: https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/41
    merged_into: null
    sequencing_note: "Independent of S1 and S3. Most implementation-heavy — touches HARNESS.md, scripts/, and CI workflow."
  - id: S3
    title: "Research adversarial review gate"
    scope: "Add the research-reviewer gate constraint to HARNESS.md. Rule: no research note is acted on without a research-reviewer pass. Mirrors existing 'PRs have adjudicated objections' constraint (agent, harness-enforcer, pr scope)."
    decision_focus: "Confirm agent enforcement via harness-enforcer and pr scope match the diaboli precedent."
    lens_used: acceptance-criterion
    disposition: accepted
    disposition_rationale: "Mirrors existing 'PRs have adjudicated objections' exactly. Agent enforcement via harness-enforcer, pr scope. One HARNESS.md entry."
    file_as_issue: false
    issue_url: null
    merged_into: null
    sequencing_note: "Independent of S1 and S2. Only touches HARNESS.md."
---
