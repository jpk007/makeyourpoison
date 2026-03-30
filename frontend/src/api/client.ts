import axios from 'axios'
import type {
  SaveConfigResponse,
  StartBuildResponse,
  BuildStatus,
  PackageSearchResponse,
  DistroConfig,
  GetJobsResponse,
} from '@distroforge/shared'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000/api',
  timeout: 30_000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// ─── Interceptors ─────────────────────────────────────────────────────────
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (axios.isAxiosError(error)) {
      const status = error.response?.status
      if (status === 429) {
        const retryAfter = error.response?.headers['retry-after']
        const msg = retryAfter
          ? `Too many builds. Retry after ${retryAfter}s.`
          : 'Too many builds in queue. Please wait.'
        return Promise.reject(new Error(msg))
      }
    }
    return Promise.reject(error)
  }
)

// ─── Endpoint wrappers ─────────────────────────────────────────────────────
export const saveConfig = (config: DistroConfig): Promise<SaveConfigResponse> =>
  api.post<SaveConfigResponse>('/config', config).then((r) => r.data)

export const startBuild = (configId: string): Promise<StartBuildResponse> =>
  api.post<StartBuildResponse>('/build/start', { configId }).then((r) => r.data)

export const getBuildStatus = (jobId: string): Promise<BuildStatus> =>
  api.get<BuildStatus>(`/build/status/${jobId}`).then((r) => r.data)

export const searchPackages = (q: string): Promise<PackageSearchResponse> =>
  api.get<PackageSearchResponse>('/packages/search', { params: { q } }).then((r) => r.data)

export const pingServer = (): Promise<{ ok: boolean; ts: number }> =>
  api.get<{ ok: boolean; ts: number }>('/ping').then((r) => r.data)

export const getJobs = (limit = 50, offset = 0): Promise<GetJobsResponse> =>
  api.get<GetJobsResponse>('/build/jobs', { params: { limit, offset } }).then(r => r.data)
