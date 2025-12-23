---
layout: page
title: Latent & Implicit Thinking – Going Beyond CoT Reasoning
---

We are pleased to announce the **Latent & Implicit Thinking – Going Beyond CoT Reasoning (LIT)** workshop at ICLR 2026.

## Introduction

AI models have demonstrated remarkable reasoning capabilities by explicitly generating intermediate steps in natural language, an approach known as Chain-of-Thought (CoT) reasoning. While CoT reasoning has become the dominant paradigm for reasoning in AI systems, it incurs substantial computational costs due to the increasing length and complexity of the generated reasoning chains. Moreover, although autoregressive natural language reasoning aligns intuitively with human cognition, it may not represent the most efficient or effective internal computation medium for neural networks. Thus, emerging bodies of research are exploring alternative forms of intermediate reasoning, including using continuous hidden representations, learning discrete reasoning tokens optimized for efficiency rather than readability, and other non-autoregressive thinking approaches. These alternative paradigms present promising opportunities to achieve more efficient and potentially more powerful implicit reasoning capabilities within future AI models.

The proposed workshop, **Latent & Implicit Thinking – Going Beyond CoT Reasoning (LIT)**, seeks to unify these diverse yet complementary research directions. By fostering interdisciplinary dialogue among researchers pursuing implicit reasoning strategies, novel model architectures, and non-autoregressive generative frameworks, we aim to deepen our collective understanding of how to harness and extend LLMs' inherent implicit reasoning capacities.

#### News

**December 2025** Workshop website, schedule, and call for papers released.

**December 2025** The [call for papers](https://latent-implicit-thinking.github.io/callforpapers/) is out! 

**TBA** The workshop [schedule](https://latent-implicit-thinking.github.io/schedule/) will be available soon.

## Topics of Interest

We invite original submissions on, but not limited to, the following themes:

- **Special Thinking Tokens**: Explicit CoT compressed to special tokens (e.g., continuous thought tokens, VQ-VAE codes, gist tokens). CoT augmentation via filler or planning tokens.
- **Looped Architectures**: Recurrence mechanisms (loop unrolling, dynamic halting). Training curricula and stability for deep iterative models.
- **Stateful Reasoning**: Leveraging key/value caches for multi-step inference. Comparisons between pure activation vs. cache-augmented loops.
- **Parallel Reasoning**: Diffusion models for bidirectional, iterative denoising-based reasoning. Fractal generative frameworks and next-block prediction. Parallel CoTs generation.
- **Training Strategies**: Training strategies to enable neural networks to reason in latent space or extract their latent thoughts (e.g., curriculum learning, distillation, reinforcement learning in the latent space).
- **Theoretical Analysis**: Theory or analysis on advantages of reasoning in the latent space (e.g., reasoning by superposition, theoretical bounds on reasoning depth vs. layer count, layer-wise or head-wise specialization).
- **Evaluation and Benchmarks**: Metrics for latent vs. explicit CoT capabilities. Datasets and tasks that stress ultra-deep or multi-hop latent reasoning.
- **Limitations and Safety**: Understanding pros and cons of latent and explicit CoT, and interpretability & faithfulness of reasoning from a safety and alignment perspective.

## Important Dates

- **Workshop website, schedule, and call for papers release**: December 2025
- **Submission deadline**: January 30, 2026
- **Reviewing period**: January 30 - February 28, 2026
- **Notification of acceptance**: March 1, 2026, 11:59pm AoE
- **Camera-ready deadline**: March 10, 2026
- **Workshop date**: April/May 2026 (TBA - during ICLR 2026 main conference week)

