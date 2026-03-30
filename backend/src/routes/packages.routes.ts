import { Router } from 'express'
import { z } from 'zod'
import { packageService } from '../services/package.service'

const router = Router()

const SearchQuerySchema = z.object({
  q: z.string().optional().default(''),
})

router.get('/search', (req, res, next) => {
  try {
    const result = SearchQuerySchema.safeParse(req.query)
    if (!result.success) {
      res.status(400).json({ errors: result.error.flatten() })
      return
    }
    const packages = packageService.search(result.data.q)
    res.json({ packages })
  } catch (err) {
    next(err)
  }
})

export default router
