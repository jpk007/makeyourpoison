import { z } from 'zod'

// ─── Core config schema ────────────────────────────────────────────────────
export const DistroConfigSchema = z.object({
  base: z.literal('scratch'),
  desktop: z.enum(['gnome', 'kde', 'xfce', 'hyprland', 'none']),
  kernel: z.enum(['generic', 'lowlatency', 'zen', 'hardened']),
  packages: z.array(z.string()),
  appBundles: z.array(z.string()),
  locale: z.object({
    timezone: z.string(),
    language: z.string(),
    keyboard: z.string(),
  }),
  boot: z.object({
    grubTheme: z.string(),
    splashScreen: z.boolean(),
    timeout: z.number().int().min(0).max(60),
  }),
  isoName: z.string()
    .min(1)
    .max(64)
    .regex(/^[a-zA-Z0-9_-]+$/, 'Only letters, numbers, hyphens and underscores')
    .default('makeyourpoison'),
})

export type DistroConfig = z.infer<typeof DistroConfigSchema>

// ─── API request schemas ───────────────────────────────────────────────────
export const SaveConfigSchema = DistroConfigSchema

export const StartBuildSchema = z.object({
  configId: z.string().uuid(),
})

// ─── API response types ────────────────────────────────────────────────────
export const SaveConfigResponseSchema = z.object({
  configId: z.string().uuid(),
})

export const StartBuildResponseSchema = z.object({
  jobId: z.string(),
})

export const BuildStatusSchema = z.object({
  status: z.enum(['waiting', 'active', 'completed', 'failed', 'delayed']),
  progress: z.number().min(0).max(100),
  logs: z.array(z.string()),
})

export const PackageSchema = z.object({
  id: z.string(),
  name: z.string(),
  description: z.string(),
  category: z.string(),
  size: z.number(), // MB
})

export const PackageSearchResponseSchema = z.object({
  packages: z.array(PackageSchema),
})

// ─── Inferred types ────────────────────────────────────────────────────────
export type SaveConfigRequest = z.infer<typeof SaveConfigSchema>
export type SaveConfigResponse = z.infer<typeof SaveConfigResponseSchema>
export type StartBuildRequest = z.infer<typeof StartBuildSchema>
export type StartBuildResponse = z.infer<typeof StartBuildResponseSchema>
export type BuildStatus = z.infer<typeof BuildStatusSchema>
export type Package = z.infer<typeof PackageSchema>
export type PackageSearchResponse = z.infer<typeof PackageSearchResponseSchema>

// ─── WebSocket frame types ─────────────────────────────────────────────────
export type WsLogFrame = { type: 'log'; line: string }
export type WsProgressFrame = { type: 'progress'; percent: number }
export type WsCompleteFrame = { type: 'complete'; isoPath: string }
export type WsErrorFrame = { type: 'error'; message: string }
export type WsFrame = WsLogFrame | WsProgressFrame | WsCompleteFrame | WsErrorFrame

// ─── Distro metadata ───────────────────────────────────────────────────────
export const BASE_DISTROS = ['scratch'] as const
export const DESKTOP_ENVS = ['gnome', 'kde', 'xfce', 'hyprland', 'none'] as const
export const KERNELS = ['generic', 'lowlatency', 'zen', 'hardened'] as const
export const APP_BUNDLES = ['dev', 'office', 'gaming', 'minimal'] as const

export type BaseDistro = typeof BASE_DISTROS[number]
export type DesktopEnv = typeof DESKTOP_ENVS[number]
export type Kernel = typeof KERNELS[number]
export type AppBundle = typeof APP_BUNDLES[number]

// ─── Job record ────────────────────────────────────────────────────────────
export const JobRecordSchema = z.object({
  id: z.string(),
  configId: z.string().uuid(),
  status: z.enum(['waiting', 'active', 'completed', 'failed', 'delayed']),
  progress: z.number().min(0).max(100),
  isoPath: z.string().nullable(),
  base: z.string().nullable(),
  desktop: z.string().nullable(),
  error: z.string().nullable(),
  logs: z.array(z.string()),
  createdAt: z.string(),
  updatedAt: z.string(),
})

export type JobRecord = z.infer<typeof JobRecordSchema>

export const GetJobsResponseSchema = z.object({
  jobs: z.array(JobRecordSchema),
  total: z.number(),
})

export type GetJobsResponse = z.infer<typeof GetJobsResponseSchema>
