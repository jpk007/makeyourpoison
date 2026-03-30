import { Router } from 'express'
import { SaveConfigSchema } from '@distroforge/shared'
import { validate } from '../middleware/validate'
import { configService } from '../services/config.service'
import { DistroConfig } from '@distroforge/shared'

const router = Router()

router.post('/', validate(SaveConfigSchema), async (req, res, next) => {
  try {
    const result = await configService.save(req.body as DistroConfig)
    res.status(201).json({ configId: result.configId })
  } catch (err) {
    next(err)
  }
})

export default router
