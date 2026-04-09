const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

if (!admin.apps.length) {
  admin.initializeApp();
}

function getTransporter() {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || 587);
  const secure = String(process.env.SMTP_SECURE || "false") === "true";
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !user || !pass) {
    throw new Error("Missing SMTP credentials. Set SMTP_HOST, SMTP_USER, SMTP_PASS.");
  }

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
  });
}

exports.sendVerificationOtp = onDocumentUpdated("users/{userId}", async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};

  const previousOtp = before.VerificationOtp;
  const otp = after.VerificationOtp;
  const toEmail = after.OtpEmail;
  const expiresAt = after.OtpTimestamp;

  // Send only when a new OTP is set/changed.
  if (!otp || otp === previousOtp) {
    return;
  }

  if (!toEmail) {
    logger.warn("OTP exists but OtpEmail is missing", { userId: event.params.userId });
    return;
  }

  const appName = "Quick Parcel";
  const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;

  const subject = `${appName} - Your verification code`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto;">
      <h2 style="color:#0D7D8F;">Verify your email</h2>
      <p>Your OTP code is:</p>
      <div style="font-size: 28px; font-weight: 700; letter-spacing: 6px; margin: 14px 0; color:#1A1A2E;">${otp}</div>
      <p>This code will expire at <b>${expiresAt || "soon"}</b>.</p>
      <p>If you did not request this, you can ignore this email.</p>
      <hr style="border:none;border-top:1px solid #eee;margin:20px 0;" />
      <p style="font-size:12px;color:#6b7280;">${appName}</p>
    </div>
  `;

  const text = [
    "Verify your email",
    `OTP: ${otp}`,
    expiresAt ? `Expires at: ${expiresAt}` : "",
    "If you did not request this, ignore this email.",
  ]
    .filter(Boolean)
    .join("\n");

  try {
    const transporter = getTransporter();
    await transporter.sendMail({
      from: fromAddress,
      to: toEmail,
      subject,
      text,
      html,
    });

    logger.info("OTP email sent", {
      userId: event.params.userId,
      toEmail,
    });
  } catch (error) {
    logger.error("Failed to send OTP email", {
      userId: event.params.userId,
      error: error instanceof Error ? error.message : String(error),
    });
    throw error;
  }
});
