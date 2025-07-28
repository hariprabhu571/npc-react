import React from 'react';
import { FiShield } from 'react-icons/fi';

interface CompanyLogoProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  showFallback?: boolean;
}

const CompanyLogo: React.FC<CompanyLogoProps> = ({ 
  size = 'md', 
  className = '', 
  showFallback = true 
}) => {
  const sizeClasses = {
    sm: 'w-6 h-6',
    md: 'w-8 h-8', 
    lg: 'w-12 h-12',
    xl: 'w-16 h-16'
  };

  const containerClasses = {
    sm: 'w-8 h-8',
    md: 'w-10 h-10',
    lg: 'w-16 h-16',
    xl: 'w-20 h-20'
  };

  const fallbackIconSizes = {
    sm: 'w-4 h-4',
    md: 'w-6 h-6',
    lg: 'w-8 h-8', 
    xl: 'w-10 h-10'
  };

  return (
    <div className={`bg-teal-600 rounded-lg flex items-center justify-center overflow-hidden ${containerClasses[size]} ${className}`}>
      <img 
        src="/images/logo-npc.png" 
        alt="NPC Pest Control Logo"
        className={`${sizeClasses[size]} object-contain`}
        onError={(e) => {
          if (showFallback) {
            // Fallback to shield icon if logo fails to load
            e.currentTarget.style.display = 'none';
            e.currentTarget.nextElementSibling?.classList.remove('hidden');
          }
        }}
      />
      {showFallback && (
        <FiShield className={`text-white hidden ${fallbackIconSizes[size]}`} />
      )}
    </div>
  );
};

export default CompanyLogo; 