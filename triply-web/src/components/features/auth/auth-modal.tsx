"use client";

import { useState } from "react";
import { X, Mail, Loader2 } from "lucide-react";
import { useAuth } from "@/contexts/auth-context";
import { Button } from "@/components/ui/button";
import { FloatingInput } from "@/components/ui/floating-input";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";

// Social icons as SVG components
function GoogleIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24">
      <path
        fill="#4285F4"
        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
      />
      <path
        fill="#34A853"
        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
      />
      <path
        fill="#FBBC05"
        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
      />
      <path
        fill="#EA4335"
        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
      />
    </svg>
  );
}

function AppleIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
    </svg>
  );
}

function FacebookIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="#1877F2">
      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
    </svg>
  );
}

type AuthView = "main" | "email-signup" | "forgot-password";

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultView?: AuthView;
}

export function AuthModal({ isOpen, onClose, defaultView = "main" }: AuthModalProps) {
  const [view, setView] = useState<AuthView>(defaultView);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const {
    signInWithEmail,
    signUpWithEmail,
    signInWithGoogle,
    signInWithApple,
    signInWithFacebook,
    resetPassword,
  } = useAuth();

  const resetState = () => {
    setEmail("");
    setPassword("");
    setName("");
    setError(null);
    setSuccessMessage(null);
    setIsLoading(false);
  };

  const handleClose = () => {
    resetState();
    setView("main");
    onClose();
  };

  const handleGoogleSignIn = async () => {
    setIsLoading(true);
    setError(null);
    const { error } = await signInWithGoogle();
    if (error) {
      setError(error.message);
      setIsLoading(false);
    }
  };

  const handleAppleSignIn = async () => {
    setIsLoading(true);
    setError(null);
    const { error } = await signInWithApple();
    if (error) {
      setError(error.message);
      setIsLoading(false);
    }
  };

  const handleFacebookSignIn = async () => {
    setIsLoading(true);
    setError(null);
    const { error } = await signInWithFacebook();
    if (error) {
      setError(error.message);
      setIsLoading(false);
    }
  };

  const handleEmailSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Please fill in all fields");
      return;
    }
    setIsLoading(true);
    setError(null);
    const { error } = await signInWithEmail(email, password);
    if (error) {
      setError(error.message);
      setIsLoading(false);
    } else {
      handleClose();
    }
  };

  const handleEmailSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Please fill in all fields");
      return;
    }
    if (password.length < 6) {
      setError("Password must be at least 6 characters");
      return;
    }
    setIsLoading(true);
    setError(null);
    const { error } = await signUpWithEmail(email, password, name);
    if (error) {
      setError(error.message);
      setIsLoading(false);
    } else {
      setSuccessMessage("Check your email to confirm your account!");
      setIsLoading(false);
    }
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) {
      setError("Please enter your email");
      return;
    }
    setIsLoading(true);
    setError(null);
    const { error } = await resetPassword(email);
    if (error) {
      setError(error.message);
    } else {
      setSuccessMessage("Password reset link sent to your email!");
    }
    setIsLoading(false);
  };

  const renderMainView = () => (
    <div className="space-y-6">
      {/* Email/Password Form */}
      <form onSubmit={handleEmailSignIn} className="space-y-3">
        <FloatingInput
          type="email"
          label="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          disabled={isLoading}
          error={!!error}
        />

        <FloatingInput
          type="password"
          label="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          disabled={isLoading}
          error={!!error}
        />

        {error && (
          <p className="text-sm text-red-500">{error}</p>
        )}

        <Button
          type="submit"
          className="w-full h-12 text-base bg-primary hover:bg-primary/90 text-white rounded-lg"
          disabled={isLoading}
        >
          {isLoading ? (
            <Loader2 className="h-5 w-5 animate-spin" />
          ) : (
            "Continue"
          )}
        </Button>

        <button
          type="button"
          onClick={() => {
            resetState();
            setView("forgot-password");
          }}
          className="text-sm text-primary hover:underline w-full text-left"
        >
          Forgot password?
        </button>
      </form>

      {/* Sign up link */}
      <p className="text-center text-sm text-muted-foreground">
        Don&apos;t have an account?{" "}
        <button
          type="button"
          onClick={() => {
            resetState();
            setView("email-signup");
          }}
          className="text-primary hover:underline font-medium"
        >
          Sign up
        </button>
      </p>

      {/* Divider */}
      <div className="relative">
        <div className="absolute inset-0 flex items-center">
          <span className="w-full border-t border-border" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-background px-2 text-muted-foreground">or</span>
        </div>
      </div>

      {/* Social Buttons */}
      <div className="space-y-3">
        <Button
          variant="outline"
          className="w-full h-12 text-base font-normal relative"
          onClick={handleGoogleSignIn}
          disabled={isLoading}
        >
          <GoogleIcon className="h-5 w-5 absolute left-4" />
          Continue with Google
        </Button>

        <Button
          variant="outline"
          className="w-full h-12 text-base font-normal relative"
          onClick={handleAppleSignIn}
          disabled={isLoading}
        >
          <AppleIcon className="h-5 w-5 absolute left-4" />
          Continue with Apple
        </Button>

        <Button
          variant="outline"
          className="w-full h-12 text-base font-normal relative"
          onClick={handleFacebookSignIn}
          disabled={isLoading}
        >
          <FacebookIcon className="h-5 w-5 absolute left-4" />
          Continue with Facebook
        </Button>
      </div>
    </div>
  );

  const renderEmailSignUpView = () => (
    <div className="space-y-6">
      {/* Back button and header */}
      <div>
        <button
          onClick={() => {
            resetState();
            setView("main");
          }}
          className="text-sm text-muted-foreground hover:text-foreground mb-4"
        >
          ← Back
        </button>
        <h2 className="text-2xl font-semibold text-foreground">
          Create an account
        </h2>
      </div>

      {successMessage ? (
        <div className="text-center py-8">
          <div className="w-16 h-16 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center mx-auto mb-4">
            <Mail className="h-8 w-8 text-green-600 dark:text-green-400" />
          </div>
          <p className="text-foreground font-medium mb-2">Check your email!</p>
          <p className="text-muted-foreground text-sm">{successMessage}</p>
        </div>
      ) : (
        <>
          {/* Form */}
          <form onSubmit={handleEmailSignUp} className="space-y-3">
            <FloatingInput
              type="text"
              label="Name (optional)"
              value={name}
              onChange={(e) => setName(e.target.value)}
              disabled={isLoading}
            />

            <FloatingInput
              type="email"
              label="Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={isLoading}
              error={!!error}
            />

            <FloatingInput
              type="password"
              label="Password (at least 6 characters)"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={isLoading}
              error={!!error}
            />

            {error && (
              <p className="text-sm text-red-500">{error}</p>
            )}

            <Button
              type="submit"
              className="w-full h-12 text-base bg-primary hover:bg-primary/90 text-white rounded-lg"
              disabled={isLoading}
            >
              {isLoading ? (
                <Loader2 className="h-5 w-5 animate-spin" />
              ) : (
                "Create Account"
              )}
            </Button>
          </form>

          {/* Sign in link */}
          <p className="text-center text-sm text-muted-foreground">
            Already have an account?{" "}
            <button
              onClick={() => {
                resetState();
                setView("main");
              }}
              className="text-primary hover:underline font-medium"
            >
              Sign in
            </button>
          </p>
        </>
      )}
    </div>
  );

  const renderForgotPasswordView = () => (
    <div className="space-y-6">
      {/* Back button and header */}
      <div>
        <button
          onClick={() => {
            resetState();
            setView("main");
          }}
          className="text-sm text-muted-foreground hover:text-foreground mb-4"
        >
          ← Back
        </button>
        <h2 className="text-2xl font-semibold text-foreground">
          Reset password
        </h2>
        <p className="text-muted-foreground mt-2">
          Enter your email and we&apos;ll send you a reset link
        </p>
      </div>

      {successMessage ? (
        <div className="text-center py-8">
          <div className="w-16 h-16 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center mx-auto mb-4">
            <Mail className="h-8 w-8 text-green-600 dark:text-green-400" />
          </div>
          <p className="text-foreground font-medium mb-2">Check your email!</p>
          <p className="text-muted-foreground text-sm">{successMessage}</p>
        </div>
      ) : (
        <form onSubmit={handleForgotPassword} className="space-y-3">
          <FloatingInput
            type="email"
            label="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={isLoading}
            error={!!error}
          />

          {error && (
            <p className="text-sm text-red-500">{error}</p>
          )}

          <Button
            type="submit"
            className="w-full h-12 text-base bg-primary hover:bg-primary/90 text-white rounded-lg"
            disabled={isLoading}
          >
            {isLoading ? (
              <Loader2 className="h-5 w-5 animate-spin" />
            ) : (
              "Send Reset Link"
            )}
          </Button>
        </form>
      )}
    </div>
  );

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent
        className={cn(
          "p-0 gap-0 overflow-hidden",
          // Mobile: bottom sheet style
          "fixed bottom-0 left-0 right-0 top-auto translate-x-0 translate-y-0 rounded-t-3xl rounded-b-none w-full max-w-full max-h-[90vh] overflow-y-auto",
          // Desktop: centered modal
          "sm:bottom-auto sm:left-[50%] sm:top-[50%] sm:translate-x-[-50%] sm:translate-y-[-50%] sm:rounded-3xl sm:max-w-md sm:max-h-none",
          // Animation
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=open]:slide-in-from-bottom data-[state=closed]:slide-out-to-bottom",
          "sm:data-[state=open]:slide-in-from-bottom-0 sm:data-[state=open]:fade-in-0 sm:data-[state=closed]:fade-out-0"
        )}
        showCloseButton={false}
      >
        {/* Header with close button */}
        <DialogHeader className="px-6 py-4 border-b border-border">
          <div className="flex items-center justify-center relative">
            <button
              onClick={handleClose}
              className="absolute left-0 p-1 rounded-full hover:bg-muted transition-colors"
            >
              <X className="h-5 w-5" />
            </button>
            <DialogTitle className="text-base font-semibold">
              {view === "main" && "Log in or sign up"}
              {view === "email-signup" && "Sign up"}
              {view === "forgot-password" && "Reset password"}
            </DialogTitle>
          </div>
        </DialogHeader>

        {/* Content */}
        <div className="px-6 py-6">
          {view === "main" && renderMainView()}
          {view === "email-signup" && renderEmailSignUpView()}
          {view === "forgot-password" && renderForgotPasswordView()}
        </div>
      </DialogContent>
    </Dialog>
  );
}
