import { Request, Response, NextFunction } from 'express'

export interface AppError extends Error {
  statusCode?: number
  details?: unknown
}

export const errorHandler = (
  err: AppError,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  const statusCode = err.statusCode ?? 500
  const message = err.message ?? 'Internal Server Error'

  if (process.env.NODE_ENV !== 'production') {
    console.error('[Error]', err)
  }

  res.status(statusCode).json({
    error: message,
    ...(err.details !== undefined && { details: err.details }),
  })
}

export function createError(message: string, statusCode: number, details?: unknown): AppError {
  const err: AppError = new Error(message)
  err.statusCode = statusCode
  err.details = details
  return err
}
