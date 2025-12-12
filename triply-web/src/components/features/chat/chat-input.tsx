"use client";

import { useState, useRef, useEffect, useCallback } from "react";
import { Loader2, Plane, Palmtree, Calendar } from "lucide-react";
import { AnimatePresence, motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { LottieIcon } from "@/components/ui/lottie-icon";
import { cn } from "@/lib/utils";

// Web Speech API types
interface SpeechRecognitionEvent extends Event {
  results: SpeechRecognitionResultList;
  resultIndex: number;
}

interface SpeechRecognitionResultList {
  length: number;
  item(index: number): SpeechRecognitionResult;
  [index: number]: SpeechRecognitionResult;
}

interface SpeechRecognitionResult {
  length: number;
  item(index: number): SpeechRecognitionAlternative;
  [index: number]: SpeechRecognitionAlternative;
  isFinal: boolean;
}

interface SpeechRecognitionAlternative {
  transcript: string;
  confidence: number;
}

interface SpeechRecognition extends EventTarget {
  continuous: boolean;
  interimResults: boolean;
  lang: string;
  onresult: ((event: SpeechRecognitionEvent) => void) | null;
  onerror: ((event: Event) => void) | null;
  onend: (() => void) | null;
  start(): void;
  stop(): void;
  abort(): void;
}

declare global {
  interface Window {
    SpeechRecognition: new () => SpeechRecognition;
    webkitSpeechRecognition: new () => SpeechRecognition;
  }
}

const suggestions = [
  {
    label: "Plan a trip to Japan",
    icon: Plane,
  },
  {
    label: "Best beaches in Europe",
    icon: Palmtree,
  },
  {
    label: "Paris itinerary",
    icon: Calendar,
  },
];

// Voice recording states
type VoiceState = "idle" | "tooltip" | "recording";

// Audio equalizer bars component - grows from right to left with real audio levels
function AudioEqualizer({ levels }: { levels: number[] }) {
  return (
    <div className="flex-1 flex items-center justify-end gap-[2px] h-6">
      {levels.map((level, i) => (
        <div
          key={i}
          className="w-[3px] bg-primary rounded-full transition-all duration-75 ease-out"
          style={{
            height: `${Math.max(4, Math.pow(level, 0.6) * 24)}px`,
            opacity: 0.5 + level * 0.5
          }}
        />
      ))}
    </div>
  );
}

// Microphone button with voice input UI
function MicrophoneButton({
  onTranscript,
  isRecording,
  setIsRecording,
  audioLevels,
}: {
  onTranscript: (text: string) => void;
  isRecording: boolean;
  setIsRecording: (recording: boolean) => void;
  audioLevels: number[];
}) {
  const [isHovered, setIsHovered] = useState(false);
  const [showTooltip, setShowTooltip] = useState(false);
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const tooltipTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const holdTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const isHoldingRef = useRef(false);

  // Clear tooltip timeout on unmount
  useEffect(() => {
    return () => {
      if (tooltipTimeoutRef.current) clearTimeout(tooltipTimeoutRef.current);
      if (holdTimeoutRef.current) clearTimeout(holdTimeoutRef.current);
    };
  }, []);

  // Request microphone permission
  const requestPermission = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.getTracks().forEach(track => track.stop());
      setHasPermission(true);
      return true;
    } catch {
      setHasPermission(false);
      return false;
    }
  }, []);

  // Handle tap/click - show tooltip
  const handleClick = async () => {
    if (isRecording) {
      // Stop recording on click if already recording
      setIsRecording(false);
      return;
    }

    // Request permission if not granted yet
    if (hasPermission === null) {
      const granted = await requestPermission();
      if (!granted) return;
    }

    // Show tooltip
    setShowTooltip(true);

    // Hide tooltip after 2 seconds
    if (tooltipTimeoutRef.current) clearTimeout(tooltipTimeoutRef.current);
    tooltipTimeoutRef.current = setTimeout(() => {
      setShowTooltip(false);
    }, 2000);
  };

  // Handle mouse/touch down - start hold detection
  const handlePointerDown = () => {
    if (hasPermission === false) return;

    isHoldingRef.current = true;

    // Start recording after 300ms hold
    holdTimeoutRef.current = setTimeout(() => {
      if (isHoldingRef.current) {
        setShowTooltip(false);
        setIsRecording(true);
      }
    }, 300);
  };

  // Handle mouse/touch up - stop recording
  const handlePointerUp = () => {
    isHoldingRef.current = false;
    if (holdTimeoutRef.current) clearTimeout(holdTimeoutRef.current);

    if (isRecording) {
      setIsRecording(false);
    }
  };

  // Handle pointer leave
  const handlePointerLeave = () => {
    isHoldingRef.current = false;
    setIsHovered(false);
    if (holdTimeoutRef.current) clearTimeout(holdTimeoutRef.current);
  };

  return (
    <div className="relative">
      {/* Tooltip */}
      <AnimatePresence>
        {showTooltip && !isRecording && (
          <motion.div
            initial={{ opacity: 0, y: 8, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 8, scale: 0.9 }}
            transition={{ duration: 0.15 }}
            className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-1.5
                       bg-background border border-border rounded-lg shadow-lg
                       whitespace-nowrap text-sm text-foreground z-50"
          >
            <div className="flex items-center gap-1.5">
              <span>Hold to record</span>
            </div>
            {/* Tooltip arrow */}
            <div className="absolute top-full left-1/2 -translate-x-1/2 -mt-px">
              <div className="w-2 h-2 bg-background border-r border-b border-border rotate-45 -translate-y-1" />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <Button
        type="button"
        size="icon"
        variant="ghost"
        onClick={handleClick}
        onPointerDown={handlePointerDown}
        onPointerUp={handlePointerUp}
        onPointerLeave={handlePointerLeave}
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        className={cn(
          "h-10 w-10 rounded-xl shrink-0 transition-all duration-200",
          isRecording
            ? "text-primary bg-primary/20 hover:bg-primary/30"
            : "text-muted-foreground hover:text-primary hover:bg-primary/10"
        )}
      >
        <LottieIcon
          variant="misc"
          name="microphone"
          size={20}
          isHovered={isHovered || isRecording}
        />
      </Button>
    </div>
  );
}

// Send button with Lottie animation
function SendButton({ isLoading, hasInput }: { isLoading: boolean; hasInput: boolean }) {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <Button
      type="submit"
      size="icon"
      disabled={!hasInput || isLoading}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      className={cn(
        "h-10 w-10 rounded-xl shrink-0",
        "transition-all duration-200",
        hasInput && !isLoading
          ? "bg-primary hover:bg-primary/90"
          : "bg-muted text-muted-foreground"
      )}
    >
      {isLoading ? (
        <Loader2 className="h-5 w-5 animate-spin" />
      ) : (
        <LottieIcon variant="misc" name="send" size={20} isHovered={isHovered && hasInput} />
      )}
    </Button>
  );
}

interface ChatInputProps {
  onSubmit: (message: string) => void;
  isLoading?: boolean;
  placeholder?: string;
  initialValue?: string;
  showSuggestions?: boolean;
  value?: string;
  onChange?: (value: string) => void;
  compact?: boolean;
}

export function ChatInput({
  onSubmit,
  isLoading = false,
  placeholder = "Message Toogo AI...",
  initialValue = "",
  showSuggestions = false,
  value,
  onChange,
  compact = false,
}: ChatInputProps) {
  const [internalInput, setInternalInput] = useState(initialValue);
  const [isRecording, setIsRecording] = useState(false);
  const [audioLevels, setAudioLevels] = useState<number[]>([]);
  const [interimTranscript, setInterimTranscript] = useState("");
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const mediaStreamRef = useRef<MediaStream | null>(null);
  const recognitionRef = useRef<SpeechRecognition | null>(null);

  // Maximum number of bars that can fit in the input
  const maxBars = 150;

  // Real audio level analysis and speech recognition
  useEffect(() => {
    if (!isRecording) {
      // Cleanup audio
      if (mediaStreamRef.current) {
        mediaStreamRef.current.getTracks().forEach(track => track.stop());
        mediaStreamRef.current = null;
      }
      if (audioContextRef.current) {
        audioContextRef.current.close();
        audioContextRef.current = null;
      }
      analyserRef.current = null;
      // Reset levels when stopped - fresh start next time
      setAudioLevels([]);

      // Stop speech recognition
      if (recognitionRef.current) {
        recognitionRef.current.stop();
      }
      setInterimTranscript("");
      return;
    }

    // Start with empty array - bars will be added progressively
    setAudioLevels([]);

    // Start audio analysis
    let intervalId: NodeJS.Timeout;

    const startAudioAnalysis = async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        mediaStreamRef.current = stream;

        const audioContext = new AudioContext();
        audioContextRef.current = audioContext;

        const analyser = audioContext.createAnalyser();
        analyser.fftSize = 256;
        analyser.smoothingTimeConstant = 0.3;
        analyserRef.current = analyser;

        const source = audioContext.createMediaStreamSource(stream);
        source.connect(analyser);

        // Use interval for smooth updates - add new bar every 50ms
        intervalId = setInterval(() => {
          if (analyserRef.current) {
            const dataArray = new Uint8Array(analyserRef.current.frequencyBinCount);
            analyserRef.current.getByteFrequencyData(dataArray);

            // Get RMS (root mean square) for better sensitivity
            let sum = 0;
            for (let i = 0; i < dataArray.length; i++) {
              sum += dataArray[i] * dataArray[i];
            }
            const rms = Math.sqrt(sum / dataArray.length) / 255;

            // Apply gain and normalize (multiply by 5 for more sensitivity)
            const normalizedLevel = Math.min(1, rms * 5);

            setAudioLevels(prev => {
              // Add new bar to the array (grows from right)
              // If we've reached max, remove the oldest bar from the left
              if (prev.length >= maxBars) {
                return [...prev.slice(1), normalizedLevel];
              }
              return [...prev, normalizedLevel];
            });
          }
        }, 50);
      } catch (error) {
        console.error('Failed to start audio analysis:', error);
      }
    };

    // Start speech recognition
    const startSpeechRecognition = () => {
      const SpeechRecognitionAPI = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!SpeechRecognitionAPI) {
        console.warn('Speech Recognition API not supported');
        return;
      }

      const recognition = new SpeechRecognitionAPI();
      recognition.continuous = true;
      recognition.interimResults = true;
      recognition.lang = 'en-US'; // Can be made configurable

      recognition.onresult = (event: SpeechRecognitionEvent) => {
        let interim = '';
        let final = '';

        for (let i = event.resultIndex; i < event.results.length; i++) {
          const transcript = event.results[i][0].transcript;
          if (event.results[i].isFinal) {
            final += transcript;
          } else {
            interim += transcript;
          }
        }

        // Update interim transcript for display
        setInterimTranscript(interim);

        // If we have final transcript, add it to input
        if (final) {
          setInput((prev: string) => prev + (prev ? ' ' : '') + final.trim());
        }
      };

      recognition.onerror = (event) => {
        console.error('Speech recognition error:', event);
      };

      recognition.onend = () => {
        // Recognition ended - could restart if still recording
        if (isRecording && recognitionRef.current) {
          try {
            recognitionRef.current.start();
          } catch {
            // Already started or other error
          }
        }
      };

      recognitionRef.current = recognition;

      try {
        recognition.start();
      } catch {
        // Already started
      }
    };

    startAudioAnalysis();
    startSpeechRecognition();

    return () => {
      if (intervalId) {
        clearInterval(intervalId);
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isRecording]);

  // Handle voice transcript
  const handleTranscript = (text: string) => {
    setInput(prev => prev + (prev ? ' ' : '') + text);
  };

  // Use controlled or uncontrolled input
  const input = value !== undefined ? value : internalInput;
  const inputRef = useRef(input);
  inputRef.current = input;

  const setInput = useCallback((newValue: string | ((prev: string) => string)) => {
    const resolvedValue = typeof newValue === 'function' ? newValue(inputRef.current) : newValue;
    if (onChange) {
      onChange(resolvedValue);
    } else {
      setInternalInput(resolvedValue);
    }
  }, [onChange]);

  // Auto-focus and set initial value
  useEffect(() => {
    if (initialValue && !value) {
      setInternalInput(initialValue);
    }
    textareaRef.current?.focus();
  }, [initialValue, value]);

  // Auto-resize textarea
  useEffect(() => {
    const textarea = textareaRef.current;
    if (textarea) {
      textarea.style.height = "auto";
      textarea.style.height = `${Math.min(textarea.scrollHeight, 200)}px`;
    }
  }, [input]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    onSubmit(input.trim());
    setInput("");

    // Reset textarea height
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  const handleSuggestionClick = (suggestion: string) => {
    onSubmit(suggestion);
  };

  // Show suggestions only if enabled and input is empty
  const shouldShowSuggestions = showSuggestions && !input.trim();

  return (
    <div className="bg-linear-to-t from-background via-background to-transparent pt-6">
      {/* Suggestions - above input, hidden when typing */}
      {shouldShowSuggestions && !compact && (
        <div className="mx-auto max-w-3xl pb-4">
          {/* Mobile: horizontal scroll */}
          <div className="md:hidden overflow-x-auto scrollbar-hide px-4">
            <div className="flex gap-2 w-max">
              {suggestions.map((suggestion) => {
                const Icon = suggestion.icon;
                return (
                  <button
                    key={suggestion.label}
                    onClick={() => handleSuggestionClick(suggestion.label)}
                    className={cn(
                      "inline-flex items-center gap-2 px-4 py-2 rounded-full whitespace-nowrap",
                      "text-sm text-muted-foreground",
                      "bg-muted/50 border border-border",
                      "hover:bg-primary/10 hover:text-primary hover:border-primary/30",
                      "transition-all duration-200"
                    )}
                  >
                    <Icon className="h-4 w-4" />
                    {suggestion.label}
                  </button>
                );
              })}
            </div>
          </div>
          {/* Desktop: wrapped centered */}
          <div className="hidden md:flex flex-wrap gap-2 justify-center px-4">
            {suggestions.map((suggestion) => {
              const Icon = suggestion.icon;
              return (
                <button
                  key={suggestion.label}
                  onClick={() => handleSuggestionClick(suggestion.label)}
                  className={cn(
                    "inline-flex items-center gap-2 px-4 py-2 rounded-full",
                    "text-sm text-muted-foreground",
                    "bg-muted/50 border border-border",
                    "hover:bg-primary/10 hover:text-primary hover:border-primary/30",
                    "transition-all duration-200"
                  )}
                >
                  <Icon className="h-4 w-4" />
                  {suggestion.label}
                </button>
              );
            })}
          </div>
        </div>
      )}

      <form
        onSubmit={handleSubmit}
        className={cn(
          "mx-auto px-4 pb-4 transition-all duration-300",
          compact ? "max-w-md" : "max-w-3xl"
        )}
      >
        <div
          className={cn(
            "relative flex items-end gap-3 rounded-2xl pl-4 pr-1.5 py-1.5",
            "bg-muted/50 border border-border",
            "focus-within:border-primary/50 focus-within:ring-2 focus-within:ring-primary/20",
            "transition-all duration-200"
          )}
        >
          {/* Show equalizer when recording, otherwise show textarea */}
          {isRecording ? (
            <div className="flex-1 flex items-center py-2 min-h-10 gap-2">
              {/* Show interim transcript if available */}
              {interimTranscript && (
                <span className="text-muted-foreground text-sm italic truncate max-w-[40%]">
                  {interimTranscript}
                </span>
              )}
              <AudioEqualizer levels={audioLevels} />
            </div>
          ) : (
            <textarea
              ref={textareaRef}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder={placeholder}
              rows={1}
              disabled={isLoading}
              className={cn(
                "flex-1 resize-none bg-transparent py-1.5",
                "text-foreground placeholder:text-muted-foreground",
                "focus:outline-none",
                "min-h-10 max-h-[200px]",
                "disabled:opacity-50"
              )}
            />
          )}

          <div className="flex items-center gap-1.5">
            {/* Microphone button */}
            <MicrophoneButton
              onTranscript={handleTranscript}
              isRecording={isRecording}
              setIsRecording={setIsRecording}
              audioLevels={audioLevels}
            />

            {/* Send button */}
            <SendButton isLoading={isLoading} hasInput={!!input.trim()} />
          </div>
        </div>

        <p className="text-center text-xs text-muted-foreground mt-2">
          Toogo AI can make mistakes. Consider checking important information.
        </p>
      </form>
    </div>
  );
}
