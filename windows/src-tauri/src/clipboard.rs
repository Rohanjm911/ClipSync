//! Clipboard Content Analysis, Sensitive Data Filtering, and URL Sanitization

use regex::Regex;

/// Detect if text contains sensitive secrets that should not be synced automatically
pub fn is_sensitive_content(text: &str) -> bool {
    let trimmed = text.trim();

    // 1. Private keys
    if trimmed.contains("-----BEGIN") && trimmed.contains("PRIVATE KEY-----") {
        return true;
    }

    // 2. High entropy recovery seed / mnemonic heuristic (12 or 24 words from BIP39 list or standard patterns)
    let words: Vec<&str> = trimmed.split_whitespace().collect();
    if (words.len() == 12 || words.len() == 24) && words.iter().all(|w| w.chars().all(|c| c.is_ascii_lowercase())) {
        // Potential seed phrase
        return true;
    }

    // 3. Credit Card number detection with Luhn check
    if has_valid_credit_card(trimmed) {
        return true;
    }

    // 4. API keys / tokens (AWS, GitHub, OpenAI)
    let re_tokens = Regex::new(r"(AKIA[0-9A-Z]{16}|ghp_[0-9a-zA-Z]{36}|sk-[a-zA-Z0-9]{32,})").unwrap();
    if re_tokens.is_match(trimmed) {
        return true;
    }

    false
}

/// Check if text contains a candidate credit card number satisfying Luhn check
fn has_valid_credit_card(text: &str) -> bool {
    let re_card = Regex::new(r"\b(?:\d[ -]?){12,18}\d\b").unwrap();
    for mat in re_card.find_iter(text) {
        let digits: Vec<u32> = mat
            .as_str()
            .chars()
            .filter(|c| c.is_ascii_digit())
            .filter_map(|c| c.to_digit(10))
            .collect();
        if digits.len() >= 13 && digits.len() <= 19 && luhn_check(&digits) {
            return true;
        }
    }
    false
}

/// Standard Luhn algorithm
fn luhn_check(digits: &[u32]) -> bool {
    let mut sum = 0;
    let mut alternate = false;
    for &d in digits.iter().rev() {
        if alternate {
            let doubled = d * 2;
            sum += if doubled > 9 { doubled - 9 } else { doubled };
        } else {
            sum += d;
        }
        alternate = !alternate;
    }
    sum % 10 == 0
}

/// Determine content type of clipboard text
pub fn detect_content_type(text: &str) -> String {
    let trimmed = text.trim();
    if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
        if !trimmed.contains('\n') && !trimmed.contains('\r') && !trimmed.contains(' ') {
            return "text/uri-list".to_string();
        }
    }
    "text/plain".to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_private_key_detection() {
        let key = "-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAA...\n-----END OPENSSH PRIVATE KEY-----";
        assert!(is_sensitive_content(key));

        let normal = "Just some normal notes about SSH keys";
        assert!(!is_sensitive_content(normal));
    }

    #[test]
    fn test_credit_card_detection() {
        // Standard Luhn test card (4242 4242 4242 4242)
        let valid_card = "My card is 4242 4242 4242 4242 for the order";
        assert!(is_sensitive_content(valid_card));

        let invalid_num = "My number is 1234 5678 9012 3456";
        assert!(!is_sensitive_content(invalid_num));
    }

    #[test]
    fn test_token_detection() {
        let token = "Found ghp_1234567890abcdef1234567890abcdef1234 in code";
        assert!(is_sensitive_content(token));
    }

    #[test]
    fn test_url_detection() {
        assert_eq!(detect_content_type("https://github.com/clipsync"), "text/uri-list");
        assert_eq!(detect_content_type("Hello https://github.com/clipsync world"), "text/plain");
    }
}
