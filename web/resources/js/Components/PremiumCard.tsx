import React, { ReactNode } from 'react';

interface PremiumCardProps {
  children: ReactNode;
  className?: string;
  glowColor?: 'primary' | 'secondary' | 'success' | 'danger' | 'warning' | 'none';
  hoverable?: boolean;
}

export default function PremiumCard({
  children,
  className = '',
  glowColor = 'none',
  hoverable = true
}: PremiumCardProps) {
  const glowStyles = {
    primary: 'hover:shadow-[0_12px_40px_rgba(99,102,241,0.15)] border-indigo-500/20',
    secondary: 'hover:shadow-[0_12px_40px_rgba(14,165,233,0.15)] border-cyan-500/20',
    success: 'hover:shadow-[0_12px_40px_rgba(16,185,129,0.15)] border-emerald-500/20',
    danger: 'hover:shadow-[0_12px_40px_rgba(239,68,68,0.15)] border-rose-500/20',
    warning: 'hover:shadow-[0_12px_40px_rgba(245,158,11,0.15)] border-amber-500/20',
    none: 'border-white/5'
  };

  return (
    <div
      className={`glass-panel rounded-2xl p-6 ${glowStyles[glowColor]} ${
        hoverable ? 'glass-panel-hover' : ''
      } ${className}`}
    >
      {children}
    </div>
  );
}
