import React, { ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';

interface GlassModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  maxWidth?: 'sm' | 'md' | 'lg' | 'xl';
}

export default function GlassModal({
  isOpen,
  onClose,
  title,
  children,
  maxWidth = 'md'
}: GlassModalProps) {
  if (!isOpen) return null;

  const maxWidthClasses = {
    sm: 'max-w-sm',
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-xl'
  };

  const modalContent = (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-md flex justify-center items-center p-4 sm:p-6 md:p-10">
      {/* Clickable Backdrop Overlay (closes when clicked outside) */}
      <div 
        className="fixed inset-0 transition-opacity duration-300"
        onClick={onClose}
      />

      {/* Modal Content */}
      <div 
        className={`relative w-full ${maxWidthClasses[maxWidth]} glass-panel rounded-3xl shadow-2xl border border-white/10 z-10 p-6 my-auto transform transition-all duration-300 animate-in fade-in zoom-in-95`}
      >
        {/* Header */}
        <div className="flex items-center justify-between pb-4 border-b border-white/5 mb-6">
          <h3 className="text-lg font-bold text-slate-100 bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent">
            {title}
          </h3>
          <button 
            onClick={onClose}
            className="p-1.5 rounded-xl text-slate-400 hover:text-slate-200 hover:bg-white/5 transition duration-150"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="pr-1">
          {children}
        </div>
      </div>
    </div>
  );

  return createPortal(modalContent, document.body);
}
