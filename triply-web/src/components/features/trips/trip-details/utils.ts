// Helper to parse opening hours
export function parseOpeningHours(openingHours: unknown): {
  status: string;
  statusColor: string;
  weekdayHours: string[];
} {
  if (!openingHours) {
    return { status: "Hours not available", statusColor: "text-white/50", weekdayHours: [] };
  }

  // Handle String format (e.g., "9:00 - 18:00")
  if (typeof openingHours === "string") {
    const trimmed = openingHours.trim();
    if (!trimmed) {
      return { status: "Hours not available", statusColor: "text-white/50", weekdayHours: [] };
    }
    return { status: trimmed, statusColor: "text-white/70", weekdayHours: [] };
  }

  // Handle Map/Object format (Google Places API format)
  if (typeof openingHours === "object" && openingHours !== null) {
    const hours = openingHours as { open_now?: boolean; weekday_text?: string[] };
    const weekdayText = hours.weekday_text || [];

    // If no weekday_text, return not available
    if (!weekdayText || weekdayText.length === 0) {
      return { status: "Hours not available", statusColor: "text-white/50", weekdayHours: [] };
    }

    // Get current day (JS: 0 = Sunday, 1 = Monday, etc.)
    const now = new Date();
    const currentDay = now.getDay(); // 0-6, Sunday = 0

    // Get today's hours from weekday_text
    let todayHours = "";
    if (weekdayText.length > currentDay) {
      todayHours = weekdayText[currentDay];
      // Extract just the hours part after the day name (e.g., "Monday: 9:00 AM – 6:00 PM" -> "9:00 AM – 6:00 PM")
      if (todayHours.includes(":")) {
        todayHours = todayHours.split(":").slice(1).join(":").trim();
      }
    }

    let status = "Hours not available";
    let statusColor = "text-white/50";

    // Check if today is closed
    if (todayHours.toLowerCase().includes("closed")) {
      status = "Closed";
      statusColor = "text-red-400";
    } else if (hours.open_now === true) {
      status = "Open";
      statusColor = "text-green-400";
    } else if (hours.open_now === false) {
      status = "Closed";
      statusColor = "text-red-400";
    } else {
      // No open_now info, just show "See hours"
      status = "See hours";
      statusColor = "text-white/70";
    }

    return { status, statusColor, weekdayHours: weekdayText };
  }

  return { status: "Hours not available", statusColor: "text-white/50", weekdayHours: [] };
}
