"use client";

export function ChatEmptyState() {
  return (
    <div className="flex-1 flex flex-col items-center justify-center px-4 py-12">
      <h1 className="text-2xl sm:text-3xl font-bold text-foreground mb-2 text-center">
        How can I help you travel?
      </h1>
      <p className="text-muted-foreground text-center max-w-md">
        I&apos;m your AI travel assistant. Ask me anything about destinations, itineraries, or travel tips.
      </p>
    </div>
  );
}
