"use client";

import { useState } from "react";
import Image from "next/image";
import { Button } from "@/components/ui/button";
import {
  MapPin,
  Star,
  Clock,
  Phone,
  Globe,
  Bookmark,
  X,
  DollarSign,
  Utensils,
  Navigation,
  ChevronLeft,
  ChevronRight,
  Images,
} from "lucide-react";
import { LottieIcon } from "@/components/ui/lottie-icon";
import { cn } from "@/lib/utils";
import type { AISinglePlaceResponse, AIPlace } from "@/types/ai-response";
import { FullscreenPhotoGallery } from "@/components/features/trips/trip-details/fullscreen-photo-gallery";

interface PlaceDetailsPanelProps {
  placeResponse: AISinglePlaceResponse | null;
  isOpen: boolean;
  onClose: () => void;
  onSave?: () => void;
}

export function PlaceDetailsPanel({
  placeResponse,
  isOpen,
  onClose,
  onSave,
}: PlaceDetailsPanelProps) {
  const [isSaved, setIsSaved] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [selectedPlace, setSelectedPlace] = useState<AIPlace | null>(null);
  const [isGalleryOpen, setIsGalleryOpen] = useState(false);

  if (!placeResponse || !isOpen) return null;

  const place = selectedPlace || placeResponse.place;
  const alternatives = placeResponse.alternatives || [];

  // Collect images
  const images: string[] = [];
  if (place.imageUrl) images.push(place.imageUrl);
  if (place.images) {
    for (const img of place.images) {
      if (img.url && !images.includes(img.url)) {
        images.push(img.url);
      }
    }
  }
  const hasMultipleImages = images.length > 1;

  const nextImage = () => {
    setCurrentImageIndex((prev) => (prev + 1) % images.length);
  };

  const prevImage = () => {
    setCurrentImageIndex((prev) => (prev - 1 + images.length) % images.length);
  };

  const handleSave = () => {
    setIsSaved(!isSaved);
    onSave?.();
  };

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: place.name,
          text: `Check out ${place.name} in ${place.city}!`,
        });
      } catch {
        // User cancelled
      }
    }
  };

  const handleOpenMaps = () => {
    const url = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(place.name)}&query_place_id=${place.googlePlaceId || ''}`;
    window.open(url, '_blank');
  };

  const formatPriceLevel = (level?: number): string => {
    if (!level) return '';
    return '$'.repeat(Math.min(level, 4));
  };

  return (
    <div className="h-full flex flex-col bg-transparent overflow-hidden relative">
      {/* Close button - fixed position for entire panel */}
      <button
        onClick={onClose}
        className="absolute top-4 right-4 z-50 p-2.5 rounded-full bg-black/40 backdrop-blur-xl text-white hover:bg-black/60 transition-colors"
      >
        <X className="h-5 w-5" />
      </button>

      <div className="flex-1 overflow-y-auto">
        {/* Hero Image with carousel */}
        <div className="relative p-4 pb-0">
          <div className="relative h-[300px] overflow-hidden rounded-xl">
            {images.length > 0 ? (
              <>
                <Image
                  src={images[currentImageIndex]}
                  alt={place.name}
                  fill
                  className="object-cover"
                />

                {/* Navigation arrows */}
                {hasMultipleImages && (
                  <>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="absolute left-2 top-1/2 -translate-y-1/2 h-7 w-7 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10"
                      onClick={prevImage}
                    >
                      <ChevronLeft className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="absolute right-2 top-1/2 -translate-y-1/2 h-7 w-7 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10"
                      onClick={nextImage}
                    >
                      <ChevronRight className="h-4 w-4" />
                    </Button>
                  </>
                )}

                {/* Image indicators */}
                {hasMultipleImages && (
                  <div className="absolute bottom-3 left-3 right-16 flex gap-1 z-10">
                    {images.map((_, index) => (
                      <button
                        key={index}
                        onClick={() => setCurrentImageIndex(index)}
                        className="flex-1 h-0.5 rounded transition-all"
                        style={{
                          backgroundColor: index === currentImageIndex ? "white" : "rgba(255,255,255,0.3)",
                        }}
                      />
                    ))}
                  </div>
                )}

                {/* View All Photos button */}
                {images.length > 0 && (
                  <button
                    onClick={() => setIsGalleryOpen(true)}
                    className="absolute bottom-3 right-3 z-10 flex items-center gap-1.5 px-2.5 py-1.5 bg-black/50 backdrop-blur-md text-white text-xs font-medium rounded-full hover:bg-black/70 transition-colors"
                  >
                    <Images className="h-3.5 w-3.5" />
                    <span>{images.length}</span>
                  </button>
                )}
              </>
            ) : (
              <div className="h-full bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center">
                <Utensils className="h-12 w-12 text-white/30" />
              </div>
            )}

            {/* Gradient overlay */}
            <div className="absolute bottom-0 left-0 right-0 h-16 bg-gradient-to-t from-background to-transparent" />

            {/* Place type badge */}
            <span className="absolute top-4 left-4 px-2.5 py-1 bg-white/90 text-gray-900 text-xs font-medium rounded-full capitalize">
              {place.placeType}
            </span>
          </div>
        </div>

        {/* Content */}
        <div className="px-5 pb-6 pt-5">
          {/* Header */}
          <div className="mb-6">
            <div className="flex items-start justify-between gap-3">
              <div className="flex-1">
                <h2 className="text-2xl font-bold text-white leading-tight">
                  {place.name}
                </h2>
                <div className="flex items-center gap-1.5 text-white/70 mt-2 text-base">
                  <MapPin className="h-4 w-4" />
                  <span>{place.city}, {place.country}</span>
                </div>
              </div>

              {/* Action buttons */}
              <div className="flex items-center gap-2">
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-9 w-9 rounded-full bg-white/10 hover:bg-white/20"
                  onClick={handleShare}
                >
                  <LottieIcon variant="misc" name="share" size={18} playOnHover />
                </Button>
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-9 w-9 rounded-full bg-white/10 hover:bg-white/20"
                  onClick={handleSave}
                >
                  <Bookmark
                    className={cn(
                      "h-4 w-4 transition-colors",
                      isSaved ? "fill-primary text-primary" : ""
                    )}
                  />
                </Button>
              </div>
            </div>

            {/* Stats row */}
            <div className="flex items-center gap-4 mt-4 flex-wrap text-base">
              {place.rating != null && place.rating > 0 && (
                <div className="flex items-center gap-1">
                  <Star className="h-4 w-4 text-amber-400 fill-amber-400" />
                  <span className="font-semibold text-white">{place.rating.toFixed(1)}</span>
                  {place.reviewCount && (
                    <span className="text-white/60 text-sm">({place.reviewCount})</span>
                  )}
                </div>
              )}

              {place.priceLevel && (
                <span className="text-green-400 font-medium text-lg">
                  {formatPriceLevel(place.priceLevel)}
                </span>
              )}

              {place.estimatedPrice && (
                <div className="flex items-center gap-1 text-white">
                  <DollarSign className="h-4 w-4 text-white/60" />
                  <span className="font-bold text-lg">{place.estimatedPrice}</span>
                </div>
              )}
            </div>
          </div>

          {/* Description */}
          {place.description && (
            <div className="mb-6">
              <h3 className="text-base font-semibold text-white mb-2">About</h3>
              <p className="text-white/80 text-base leading-relaxed">{place.description}</p>
            </div>
          )}

          {/* Cuisine Types */}
          {place.cuisineTypes && place.cuisineTypes.length > 0 && (
            <div className="mb-6">
              <h3 className="text-base font-semibold text-white mb-3">Cuisine</h3>
              <div className="flex flex-wrap gap-2">
                {place.cuisineTypes.map((cuisine, index) => (
                  <span
                    key={index}
                    className="px-3 py-1.5 bg-orange-500/20 text-orange-400 rounded-full text-sm"
                  >
                    {cuisine}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Highlights */}
          {place.highlights && place.highlights.length > 0 && (
            <div className="mb-6">
              <h3 className="text-base font-semibold text-white mb-3">Highlights</h3>
              <div className="flex flex-wrap gap-2">
                {place.highlights.map((highlight, index) => (
                  <span
                    key={index}
                    className="px-3 py-1.5 bg-white/10 text-white/90 rounded-full text-sm"
                  >
                    {highlight}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Opening Hours */}
          {place.openingHours && place.openingHours.length > 0 && (
            <div className="mb-6">
              <h3 className="text-base font-semibold text-white mb-3 flex items-center gap-1.5">
                <Clock className="h-4 w-4" />
                Opening Hours
              </h3>
              <div className="space-y-1">
                {place.openingHours.map((hours, index) => (
                  <p key={index} className="text-white/70 text-sm">{hours}</p>
                ))}
              </div>
            </div>
          )}

          {/* Best Time to Visit */}
          {place.bestTimeToVisit && (
            <div className="mb-6">
              <h3 className="text-base font-semibold text-white mb-2">Best Time to Visit</h3>
              <p className="text-white/80 text-base">{place.bestTimeToVisit}</p>
            </div>
          )}

          {/* Contact & Address */}
          <div className="mb-6 space-y-2.5">
            {place.address && (
              <div className="flex items-start gap-2">
                <MapPin className="h-4 w-4 text-white/60 mt-0.5" />
                <p className="text-white/80 text-sm">{place.address}</p>
              </div>
            )}

            {place.phoneNumber && (
              <div className="flex items-center gap-2">
                <Phone className="h-4 w-4 text-white/60" />
                <a
                  href={`tel:${place.phoneNumber}`}
                  className="text-primary hover:underline text-sm"
                >
                  {place.phoneNumber}
                </a>
              </div>
            )}

            {place.website && (
              <div className="flex items-center gap-2">
                <Globe className="h-4 w-4 text-white/60" />
                <a
                  href={place.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary hover:underline text-sm truncate"
                >
                  {place.website}
                </a>
              </div>
            )}
          </div>

          {/* Open in Maps button */}
          <Button
            className="w-full mb-6 gap-2 h-10"
            onClick={handleOpenMaps}
          >
            <Navigation className="h-4 w-4" />
            Open in Google Maps
          </Button>

          {/* Alternatives */}
          {alternatives.length > 0 && (
            <div>
              <h3 className="text-base font-semibold text-white mb-3">Also Consider</h3>
              <div className="space-y-2">
                {alternatives.map((alt, index) => (
                  <button
                    key={alt.id || index}
                    className={cn(
                      "w-full flex items-center gap-3 p-3 rounded-xl transition-colors text-left",
                      selectedPlace?.id === alt.id
                        ? "bg-primary/20 border border-primary/50"
                        : "bg-white/5 border border-white/10 hover:bg-white/10"
                    )}
                    onClick={() => {
                      setSelectedPlace(alt);
                      setCurrentImageIndex(0);
                    }}
                  >
                    <div className="relative w-14 h-14 rounded-lg overflow-hidden flex-shrink-0">
                      {alt.imageUrl ? (
                        <Image
                          src={alt.imageUrl}
                          alt={alt.name}
                          fill
                          className="object-cover"
                        />
                      ) : (
                        <div className="w-full h-full bg-gradient-to-br from-primary/40 to-accent/40" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h4 className="font-medium text-white text-sm line-clamp-1">{alt.name}</h4>
                      <p className="text-xs text-white/60 capitalize">{alt.placeType}</p>
                      <div className="flex items-center gap-2 mt-1 text-xs">
                        {alt.rating != null && alt.rating > 0 && (
                          <div className="flex items-center gap-0.5">
                            <Star className="h-3 w-3 text-amber-400 fill-amber-400" />
                            <span className="text-white">{alt.rating.toFixed(1)}</span>
                          </div>
                        )}
                        {alt.estimatedPrice && (
                          <span className="text-white/70">{alt.estimatedPrice}</span>
                        )}
                      </div>
                    </div>
                  </button>
                ))}
              </div>

              {/* Back to main button */}
              {selectedPlace && (
                <Button
                  variant="ghost"
                  size="sm"
                  className="w-full mt-3 text-white/70 hover:text-white h-9 text-sm"
                  onClick={() => {
                    setSelectedPlace(null);
                    setCurrentImageIndex(0);
                  }}
                >
                  Back to main recommendation
                </Button>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Fullscreen Photo Gallery */}
      <FullscreenPhotoGallery
        images={images}
        title={place.name}
        placeName={place.name}
        isOpen={isGalleryOpen}
        onClose={() => setIsGalleryOpen(false)}
        initialIndex={currentImageIndex}
        onIndexChange={setCurrentImageIndex}
      />
    </div>
  );
}
