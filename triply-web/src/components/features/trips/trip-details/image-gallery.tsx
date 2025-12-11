"use client";

import { useState, useMemo } from "react";
import Image from "next/image";
import { MapPin, Grid3X3 } from "lucide-react";
import { MobileSwipeableGallery } from "./mobile-swipeable-gallery";
import { FullscreenPhotoGallery } from "./fullscreen-photo-gallery";

export interface ImageWithSource {
  url: string;
  placeName?: string;
}

interface ImageGalleryProps {
  images: string[] | ImageWithSource[];
  title: string;
}

export function ImageGallery({ images, title }: ImageGalleryProps) {
  const [showAllPhotos, setShowAllPhotos] = useState(false);
  const [galleryStartIndex, setGalleryStartIndex] = useState(0);

  // Normalize images to always work with ImageWithSource
  const normalizedImages = useMemo(() => {
    return images.map((img) =>
      typeof img === "string" ? { url: img, placeName: undefined } : img
    );
  }, [images]);

  const allValidImages = normalizedImages.filter(
    (img) => typeof img.url === "string" && img.url.trim().length > 0
  );

  const validImages = allValidImages.slice(0, 5); // Limit to 5 for grid layout

  // Extract just URLs for components that need string arrays
  const allImageUrls = allValidImages.map((img) => img.url);
  const imageUrls = validImages.map((img) => img.url);

  // Get place name for current gallery index
  const getCurrentPlaceName = (index: number) => {
    return allValidImages[index]?.placeName || undefined;
  };

  const openGallery = (index: number = 0) => {
    setGalleryStartIndex(index);
    setShowAllPhotos(true);
  };

  if (imageUrls.length === 0) {
    return (
      <div className="max-w-4xl mx-auto px-4 sm:px-6">
        <div className="relative w-full h-[280px] md:h-[400px] bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center rounded-xl">
          <MapPin className="h-16 w-16 text-white/30" />
        </div>
      </div>
    );
  }

  // Single image layout
  if (imageUrls.length === 1) {
    return (
      <>
        <div className="max-w-4xl mx-auto px-4 sm:px-6">
          <div
            className="relative w-full h-[280px] md:h-[400px] rounded-xl overflow-hidden cursor-pointer"
            onClick={() => openGallery(0)}
          >
            <Image
              src={imageUrls[0]}
              alt={title}
              fill
              className="object-cover hover:opacity-95 transition-opacity"
              priority
            />
          </div>
        </div>
        <FullscreenPhotoGallery
          images={allImageUrls}
          title={title}
          placeName={getCurrentPlaceName(galleryStartIndex)}
          isOpen={showAllPhotos}
          onClose={() => setShowAllPhotos(false)}
          initialIndex={galleryStartIndex}
          onIndexChange={(index) => setGalleryStartIndex(index)}
          imageSourceNames={allValidImages.map((img) => img.placeName)}
        />
      </>
    );
  }

  // Airbnb-style grid layout for multiple images
  return (
    <>
      <div className="relative w-full">
        {/* Desktop: Airbnb-style grid */}
        <div className="hidden md:grid md:grid-cols-4 md:grid-rows-2 gap-2 h-[400px] max-w-4xl mx-auto px-4 sm:px-6">
          {/* Main large image */}
          <div
            className="col-span-2 row-span-2 relative rounded-xl overflow-hidden cursor-pointer"
            onClick={() => openGallery(0)}
          >
            <Image
              src={imageUrls[0]}
              alt={`${title} - Main`}
              fill
              className="object-cover hover:opacity-95 transition-opacity"
              priority
            />
          </div>

          {/* Top right images */}
          {imageUrls[1] && (
            <div
              className="relative rounded-xl overflow-hidden cursor-pointer"
              onClick={() => openGallery(1)}
            >
              <Image
                src={imageUrls[1]}
                alt={`${title} - 2`}
                fill
                className="object-cover hover:opacity-95 transition-opacity"
              />
            </div>
          )}
          {imageUrls[2] && (
            <div
              className="relative rounded-xl overflow-hidden cursor-pointer"
              onClick={() => openGallery(2)}
            >
              <Image
                src={imageUrls[2]}
                alt={`${title} - 3`}
                fill
                className="object-cover hover:opacity-95 transition-opacity"
              />
            </div>
          )}

          {/* Bottom right images */}
          {imageUrls[3] && (
            <div
              className="relative rounded-xl overflow-hidden cursor-pointer"
              onClick={() => openGallery(3)}
            >
              <Image
                src={imageUrls[3]}
                alt={`${title} - 4`}
                fill
                className="object-cover hover:opacity-95 transition-opacity"
              />
            </div>
          )}
          {imageUrls[4] ? (
            <div
              className="relative rounded-xl overflow-hidden cursor-pointer"
              onClick={() => openGallery(4)}
            >
              <Image
                src={imageUrls[4]}
                alt={`${title} - 5`}
                fill
                className="object-cover hover:opacity-95 transition-opacity"
              />
              {/* Show all photos button */}
              {allImageUrls.length > 5 && (
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    openGallery(0);
                  }}
                  className="absolute bottom-4 right-4 bg-white text-black px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 hover:bg-gray-100 transition-colors shadow-lg"
                >
                  <Grid3X3 className="h-4 w-4" />
                  Show all photos
                </button>
              )}
            </div>
          ) : (
            <div className="relative rounded-xl overflow-hidden bg-white/5" />
          )}
        </div>

        {/* Mobile: Swipeable gallery with Telegram-style indicators */}
        <div className="md:hidden">
          <MobileSwipeableGallery images={allImageUrls} title={title} />
        </div>
      </div>

      {/* Fullscreen Gallery */}
      <FullscreenPhotoGallery
        images={allImageUrls}
        title={title}
        placeName={getCurrentPlaceName(galleryStartIndex)}
        isOpen={showAllPhotos}
        onClose={() => setShowAllPhotos(false)}
        initialIndex={galleryStartIndex}
        onIndexChange={(index) => setGalleryStartIndex(index)}
        imageSourceNames={allValidImages.map((img) => img.placeName)}
      />
    </>
  );
}
