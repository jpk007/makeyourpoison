import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/step/1',
    },
    {
      path: '/step/1',
      name: 'step1',
      component: () => import('../views/Step2Desktop.vue'),
      meta: { step: 1, title: 'Desktop Environment' },
    },
    {
      path: '/step/2',
      name: 'step2',
      component: () => import('../views/Step3Packages.vue'),
      meta: { step: 2, title: 'Packages' },
    },
    {
      path: '/step/3',
      name: 'step3',
      component: () => import('../views/Step4Apps.vue'),
      meta: { step: 3, title: 'App Bundles' },
    },
    {
      path: '/step/4',
      name: 'step4',
      component: () => import('../views/Step5Kernel.vue'),
      meta: { step: 4, title: 'Kernel' },
    },
    {
      path: '/step/5',
      name: 'step5',
      component: () => import('../views/Step6Locale.vue'),
      meta: { step: 5, title: 'Locale' },
    },
    {
      path: '/step/6',
      name: 'step6',
      component: () => import('../views/Step7Boot.vue'),
      meta: { step: 6, title: 'Boot' },
    },
    {
      path: '/step/7',
      name: 'step7',
      component: () => import('../views/Step8Review.vue'),
      meta: { step: 7, title: 'Review' },
    },
    {
      path: '/step/8',
      name: 'step8',
      component: () => import('../views/Step9Build.vue'),
      meta: { step: 8, title: 'Build' },
    },
    {
      path: '/jobs',
      name: 'jobs',
      component: () => import('../views/JobsView.vue'),
      meta: { title: 'Build Jobs' },
    },
  ],
  scrollBehavior() {
    return { top: 0 }
  },
})

export default router
