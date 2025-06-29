;; GemStone: Precious Stone Authentication and Trading Platform
;; Version: 1.0.0

(define-constant ERR-UNAUTHORIZED-USER (err u1))
(define-constant ERR-STONE-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-CERTIFIED (err u3))
(define-constant ERR-INVALID-OWNERSHIP (err u4))
(define-constant ERR-INVALID-DISCOVERY-YEAR (err u5))
(define-constant ERR-INVALID-STONE-TYPE (err u6))
(define-constant ERR-INVALID-CLARITY (err u7))
(define-constant ERR-INVALID-STONE-NAME (err u8))
(define-constant ERR-INVALID-ORIGIN (err u9))

(define-constant MIN-DISCOVERY-YEAR u1700)

(define-data-var next-stone-id uint u1)

(define-map precious-stones
    uint
    {
        gemologist: principal,
        stone-name: (string-utf8 70),
        origin: (string-utf8 180),
        stone-type: (string-utf8 25),
        clarity: (string-utf8 20),
        ownership: (string-utf8 15),
        discovery-year: uint
    }
)

(define-private (validate-stone-type (stone-type (string-utf8 25)))
    (or 
        (is-eq stone-type u"Diamond")
        (is-eq stone-type u"Ruby")
        (is-eq stone-type u"Sapphire")
        (is-eq stone-type u"Emerald")
        (is-eq stone-type u"Topaz")
        (is-eq stone-type u"Amethyst")
    )
)

(define-private (validate-clarity (clarity (string-utf8 20)))
    (or 
        (is-eq clarity u"Flawless")
        (is-eq clarity u"Internally Flawless")
        (is-eq clarity u"Very Slightly")
        (is-eq clarity u"Slightly Included")
        (is-eq clarity u"Included")
    )
)

(define-private (validate-text-content (text (string-utf8 180)) (min-length uint) (max-length uint))
    (let 
        (
            (content-length (len text))
        )
        (and 
            (>= content-length min-length)
            (<= content-length max-length)
        )
    )
)

(define-public (certify-gemstone 
    (stone-name (string-utf8 70))
    (origin (string-utf8 180))
    (stone-type (string-utf8 25))
    (clarity (string-utf8 20))
    (discovery-year uint)
)
    (let
        (
            (stone-id (var-get next-stone-id))
        )
        (asserts! (validate-text-content stone-name u3 u70) ERR-INVALID-STONE-NAME)
        (asserts! (validate-text-content origin u5 u180) ERR-INVALID-ORIGIN)
        (asserts! (>= discovery-year MIN-DISCOVERY-YEAR) ERR-INVALID-DISCOVERY-YEAR)
        (asserts! (validate-stone-type stone-type) ERR-INVALID-STONE-TYPE)
        (asserts! (validate-clarity clarity) ERR-INVALID-CLARITY)
        
        (map-set precious-stones stone-id {
            gemologist: tx-sender,
            stone-name: stone-name,
            origin: origin,
            stone-type: stone-type,
            clarity: clarity,
            ownership: u"certified",
            discovery-year: discovery-year
        })
        (var-set next-stone-id (+ stone-id u1))
        (ok stone-id)
    )
)

(define-public (transfer-stone (stone-id uint))
    (let
        (
            (stone (unwrap! (map-get? precious-stones stone-id) ERR-STONE-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get gemologist stone)) ERR-UNAUTHORIZED-USER)
        (asserts! (is-eq (get ownership stone) u"certified") ERR-INVALID-OWNERSHIP)
        (ok (map-set precious-stones stone-id (merge stone { ownership: u"transferred" })))
    )
)

(define-read-only (get-stone-certificate (stone-id uint))
    (ok (map-get? precious-stones stone-id))
)

(define-read-only (get-gemologist (stone-id uint))
    (ok (get gemologist (unwrap! (map-get? precious-stones stone-id) ERR-STONE-NOT-FOUND)))
)