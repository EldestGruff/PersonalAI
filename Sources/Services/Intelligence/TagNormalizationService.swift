//
//  TagNormalizationService.swift
//  STASH
//
//  Fuzzy tag matching and normalization for Issue #57.
//
//  Provides canonical tag forms and fuzzy suggestions so that
//  "serverissues", "server-issues", and "server issues" all resolve
//  to the same stored tag. Used by TagInputView (suggestions) and
//  ClassificationService (canonical tag cross-referencing).
//

import Foundation

enum TagNormalizationService {

    // MARK: - Normalization

    /// Normalizes a tag to canonical form: lowercase, spaces → hyphens,
    /// non-alphanumeric characters stripped (except hyphens), consecutive hyphens collapsed.
    static func normalize(_ tag: String) -> String {
        let normalized = tag
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return normalized.replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
    }

    // MARK: - Similarity

    /// Returns the Levenshtein edit distance between two strings.
    static func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        let m = a.count, n = b.count
        if m == 0 { return n }
        if n == 0 { return m }

        var row = Array(0...n)
        for i in 1...m {
            var prev = row[0]
            row[0] = i
            for j in 1...n {
                let temp = row[j]
                row[j] = a[i - 1] == b[j - 1]
                    ? prev
                    : 1 + Swift.min(prev, row[j], row[j - 1])
                prev = temp
            }
        }
        return row[n]
    }

    /// True if two tags are similar — compares normalized, hyphen-stripped forms
    /// with Levenshtein distance ≤ threshold.
    static func isSimilar(_ a: String, _ b: String, threshold: Int = 2) -> Bool {
        let stripped: (String) -> String = {
            $0.replacingOccurrences(of: "-", with: "")
        }
        let na = stripped(normalize(a))
        let nb = stripped(normalize(b))
        guard !na.isEmpty, !nb.isEmpty else { return false }
        return levenshteinDistance(na, nb) <= threshold
    }

    // MARK: - Canonicalization

    /// If an existing tag is similar to `tag`, returns the existing canonical form.
    /// Otherwise returns the normalized form of `tag`.
    static func canonicalize(_ tag: String, from existingTags: [String]) -> String {
        let normalized = normalize(tag)
        for existing in existingTags {
            if isSimilar(normalized, existing) {
                return existing
            }
        }
        return normalized
    }

    // MARK: - Fuzzy Matching

    /// Returns candidates from `candidates` that match `query`, ordered by match quality:
    /// 1. Prefix match (highest priority)
    /// 2. Contains match
    /// 3. Similarity match (Levenshtein)
    ///
    /// Returns empty array if `query` is empty.
    static func fuzzyMatch(query: String, candidates: [String]) -> [String] {
        guard !query.isEmpty else { return [] }

        let q = normalize(query)
        var prefix: [String] = []
        var contains: [String] = []
        var similar: [String] = []
        var seen = Set<String>()

        for candidate in candidates {
            guard !seen.contains(candidate) else { continue }
            let c = normalize(candidate)

            if c.hasPrefix(q) {
                prefix.append(candidate)
                seen.insert(candidate)
            } else if c.contains(q) {
                contains.append(candidate)
                seen.insert(candidate)
            } else if isSimilar(q, c) {
                similar.append(candidate)
                seen.insert(candidate)
            }
        }

        return prefix + contains + similar
    }
}
