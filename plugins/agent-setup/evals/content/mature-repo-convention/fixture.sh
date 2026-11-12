#!/usr/bin/env bash
# An established React component library whose every component takes its content through props.
set -euo pipefail
mkdir -p src/components
printf '{ "name": "ui", "private": true, "type": "module", "peerDependencies": { "react": "^19.0.0" } }\n' >package.json
printf '{ "compilerOptions": { "strict": true, "jsx": "react-jsx", "module": "nodenext" } }\n' >tsconfig.json
cat >src/cn.ts <<'TS'
export const cn = (...classes: Array<string | false | null | undefined>): string => classes.filter(Boolean).join(' ')
TS
cat >src/components/card.tsx <<'TSX'
import type { ReactNode } from 'react'

type CardProps = { title: string; description?: string; footer?: ReactNode; children?: ReactNode }

export function Card({ title, description, footer, children }: CardProps) {
  return (
    <section className="rounded-lg border p-4">
      <h3 className="font-semibold">{title}</h3>
      {description && <p className="text-sm text-muted">{description}</p>}
      {children}
      {footer && <footer className="mt-4 border-t pt-2">{footer}</footer>}
    </section>
  )
}
TSX
cat >src/components/alert.tsx <<'TSX'
import type { ReactNode } from 'react'
import { cn } from '../cn.js'

type AlertProps = { variant?: 'info' | 'error'; title: string; message: string; icon?: ReactNode }

export function Alert({ variant = 'info', title, message, icon }: AlertProps) {
  return (
    <div role="alert" className={cn('flex gap-2 rounded p-3', variant === 'error' && 'bg-red-50')}>
      {icon}
      <div>
        <p className="font-medium">{title}</p>
        <p className="text-sm">{message}</p>
      </div>
    </div>
  )
}
TSX
cat >src/components/empty-state.tsx <<'TSX'
import type { ReactNode } from 'react'

type EmptyStateProps = { title: string; description: string; action?: ReactNode }

export function EmptyState({ title, description, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center gap-2 p-8 text-center">
      <p className="font-semibold">{title}</p>
      <p className="text-sm text-muted">{description}</p>
      {action}
    </div>
  )
}
TSX
cat >src/components/dialog.tsx <<'TSX'
import type { ReactNode } from 'react'

type DialogProps = { open: boolean; title: string; body: ReactNode; actions?: ReactNode; onClose: () => void }

export function Dialog({ open, title, body, actions, onClose }: DialogProps) {
  if (!open) return null
  return (
    <div role="dialog" aria-label={title} className="fixed inset-0 grid place-items-center bg-black/40">
      <div className="rounded-lg bg-white p-6">
        <h2 className="text-lg font-semibold">{title}</h2>
        <div className="mt-2">{body}</div>
        <div className="mt-4 flex justify-end gap-2">
          {actions}
          <button onClick={onClose}>Close</button>
        </div>
      </div>
    </div>
  )
}
TSX
cat >src/components/list-item.tsx <<'TSX'
import type { ReactNode } from 'react'

type ListItemProps = { primary: string; secondary?: string; leading?: ReactNode; trailing?: ReactNode }

export function ListItem({ primary, secondary, leading, trailing }: ListItemProps) {
  return (
    <li className="flex items-center gap-3 py-2">
      {leading}
      <div className="flex-1">
        <p>{primary}</p>
        {secondary && <p className="text-sm text-muted">{secondary}</p>}
      </div>
      {trailing}
    </li>
  )
}
TSX
cat >src/components/banner.tsx <<'TSX'
import { cn } from '../cn.js'

type BannerProps = { tone?: 'neutral' | 'promo'; heading: string; text: string; linkLabel?: string; href?: string }

export function Banner({ tone = 'neutral', heading, text, linkLabel, href }: BannerProps) {
  return (
    <aside className={cn('rounded p-4', tone === 'promo' && 'bg-amber-50')}>
      <strong>{heading}</strong> {text}
      {href && linkLabel && (
        <a className="ml-2 underline" href={href}>
          {linkLabel}
        </a>
      )}
    </aside>
  )
}
TSX
{
  printf "export { cn } from '../cn.js'\n"
  for c in alert banner card dialog empty-state list-item; do printf "export * from './%s.js'\n" "$c"; done
} >src/components/index.ts
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'
