# Claude Cloud Deployment — Compliance and Data Residency

Written 2026-03-09, session 009. Research notes for production deployment planning.

---

## The Question

Dan's company trusts Copilot/OpenAI in Azure because data stays within the Azure tenancy. Can Claude be deployed with equivalent data isolation guarantees? Does the API ever resolve to Anthropic infrastructure?

---

## Microsoft Azure (Foundry)

**Verdict: Data leaves Azure. Anthropic is the processor.**

The API endpoint looks like Azure:
```
https://<resource-name>.services.ai.azure.com/anthropic/v1/messages
```

But Microsoft's own docs state:

> "When you transact for Claude in Foundry, you will agree to Anthropic's terms of use and Anthropic (not Microsoft) is the processor of the data."

> "Prompts and outputs may be processed anywhere in the world, including outside of your region, for operational purposes."

The Azure URL is a proxy, not a security boundary. Data hits Anthropic's infrastructure. This would not satisfy the same compliance bar as Copilot/Azure OpenAI, where Microsoft is the processor and data stays in-tenancy.

**Sources:**
- [Data, privacy, and security for Claude models in Microsoft Foundry | Microsoft Learn](https://learn.microsoft.com/en-us/azure/foundry/responsible-ai/claude-models/data-privacy)
- [Deploy and use Claude models in Microsoft Foundry | Microsoft Learn](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/how-to/use-foundry-models-claude?view=foundry-classic)
- [Claude in Microsoft Foundry | Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/claude-in-microsoft-foundry)

---

## AWS Bedrock

**Verdict: Data stays in AWS. Anthropic does not get access.**

Claude runs natively on AWS infrastructure. Key facts:

- Anthropic does not have access to customer content.
- Data at rest (logs, knowledge bases, configurations) remains in the source region.
- Cross-region inference is available but customer data is never stored in the destination region — only transient computation moves.
- Geographic inference profiles let you constrain processing to specific regions (US, EU, Japan, Australia) using the same controls as other AWS services.

This is the same isolation model enterprises already trust for other AWS services. If the company is in AWS, Claude on Bedrock gets the same security posture as anything else running there.

**Sources:**
- [Claude on Amazon Bedrock | Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/claude-on-amazon-bedrock)
- [Amazon Bedrock | Claude](https://claude.com/partners/amazon-bedrock)
- [Cross-Region inference for Claude on Bedrock | AWS](https://aws.amazon.com/blogs/machine-learning/global-cross-region-inference-for-latest-anthropic-claude-opus-sonnet-and-haiku-models-on-amazon-bedrock-in-thailand-malaysia-singapore-indonesia-and-taiwan/)
- [Claude Opus 4.6 on Amazon Bedrock | AWS](https://aws.amazon.com/about-aws/whats-new/2026/2/claude-opus-4.6-available-amazon-bedrock/)

---

## Google Cloud Vertex AI

**Verdict: Data stays in GCP. Regional endpoints enforce residency.**

Claude runs natively on Google Cloud infrastructure. Key facts:

- Regional endpoints (e.g., `us-central1`) keep data and processing within that geographic boundary.
- Google stores and processes data only in the region you specify (except data labeling tasks and preview features).
- Meets **FedRAMP High** requirements — operates within Google Cloud's FedRAMP High authorization boundary.
- Global endpoints are available for flexibility but do **not** guarantee processing location. Use regional endpoints for data residency compliance.

**Sources:**
- [Claude models on Vertex AI | Google Cloud](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude)
- [Google Cloud Vertex AI | Claude](https://claude.com/partners/google-cloud-vertex-ai)
- [Global endpoint for Claude on Vertex AI | Google Cloud Blog](https://cloud.google.com/blog/products/ai-machine-learning/global-endpoint-for-claude-models-generally-available-on-vertex-ai)
- [Vertex AI locations | Google Cloud](https://docs.cloud.google.com/vertex-ai/docs/general/locations)

---

## Summary

| Platform | Data stays in-tenancy? | Processor | Suitable for PCI/PII? |
|----------|----------------------|-----------|----------------------|
| Azure Foundry | No | Anthropic | No — same bar as direct Anthropic API |
| AWS Bedrock | Yes | AWS | Potentially — same controls as other AWS services |
| GCP Vertex AI | Yes (regional endpoints) | Google | Potentially — FedRAMP High certified |
| Direct Anthropic API | No | Anthropic | No |

---

## Implications for Production Deployment

If the company is in AWS or GCP, Claude via Bedrock or Vertex AI could potentially receive the same compliance approval as other services in that environment. This would eliminate the need for the two-model architecture described in `external-module-loading-future.md` — Claude could handle both RE work and data profiling within a single trusted perimeter.

If the company is Azure-only (which is likely given Copilot/OpenAI is their trusted model), the Azure Foundry option does **not** provide equivalent isolation. The two-model architecture remains necessary: Claude for code-only RE, the company's trusted model for data-touching work.

The compliance team must make the final call. These are vendor claims, not security audit findings.
