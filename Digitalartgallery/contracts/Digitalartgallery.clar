;; Digital Art Gallery Contract
;; Manages the minting, listing, and purchasing of curated digital artworks

;; Error Codes
(define-constant ERR-NOT-CURATOR (err u200))
(define-constant ERR-ART-NOT-FOUND (err u201))
(define-constant ERR-INSUFFICIENT-FUNDS (err u202))
(define-constant ERR-INVALID-AMOUNT (err u203))
(define-constant ERR-ALREADY-ON-EXHIBIT (err u204))
(define-constant ERR-NOT-ON-EXHIBIT (err u205))

;; Data Maps
(define-map artworks
    { art-id: uint }
    {
        artist: principal,
        description: (string-ascii 256),
        minted-on: uint,
        displayable: bool
    }
)

(define-map gallery-exhibit
    { art-id: uint }
    {
        asking-price: uint,
        curator: principal,
        on-display: bool
    }
)

(define-map artist-portfolio
    { artist: principal }
    { total-artworks: uint }
)

;; Admin Variables
(define-data-var gallery-owner principal tx-sender)
(define-data-var next-art-id uint u1)
(define-data-var commission-rate uint u25) ;; 2.5% commission

;; Read-only Functions
(define-read-only (fetch-art (art-id uint))
    (map-get? artworks { art-id: art-id })
)

(define-read-only (fetch-exhibit (art-id uint))
    (map-get? gallery-exhibit { art-id: art-id })
)

(define-read-only (portfolio-summary (artist principal))
    (default-to { total-artworks: u0 }
        (map-get? artist-portfolio { artist: artist })
    )
)

(define-read-only (fetch-artist (art-id uint))
    (let ((record (fetch-art art-id)))
        (match record
            info (ok (get artist info))
            (err ERR-ART-NOT-FOUND)
        )
    )
)

;; Private Functions
(define-private (is-gallery-owner)
    (is-eq tx-sender (var-get gallery-owner))
)

(define-private (compute-commission (amount uint))
    (/ (* amount (var-get commission-rate)) u1000)
)

;; Public Functions
(define-public (mint-art (description (string-ascii 256)) (displayable bool))
    (let
        (
            (art-id (var-get next-art-id))
            (existing-count (get total-artworks (portfolio-summary tx-sender)))
        )
        (map-set artworks
            { art-id: art-id }
            {
                artist: tx-sender,
                description: description,
                minted-on: block-height,
                displayable: displayable
            }
        )
        (map-set artist-portfolio
            { artist: tx-sender }
            { total-artworks: (+ existing-count u1) }
        )
        (var-set next-art-id (+ art-id u1))
        (ok art-id)
    )
)

(define-public (gift-art (art-id uint) (receiver principal))
    (let ((record (fetch-art art-id)))
        (match record
            details (if (and
                (is-eq (get artist details) tx-sender)
                (get displayable details)
            )
                (begin
                    (map-set artworks
                        { art-id: art-id }
                        (merge details { artist: receiver })
                    )
                    (ok true)
                )
                ERR-NOT-CURATOR
            )
            ERR-ART-NOT-FOUND
        )
    )
)

(define-public (exhibit-art (art-id uint) (amount uint))
    (let ((record (fetch-art art-id)))
        (match record
            details
            (if (and
                (is-eq (get artist details) tx-sender)
                (> amount u0)
            )
                (begin
                    (map-set gallery-exhibit
                        { art-id: art-id }
                        {
                            asking-price: amount,
                            curator: tx-sender,
                            on-display: true
                        }
                    )
                    (ok true)
                )
                ERR-INVALID-AMOUNT
            )
            ERR-ART-NOT-FOUND
        )
    )
)

(define-public (remove-exhibit (art-id uint))
    (let ((listing (fetch-exhibit art-id)))
        (match listing
            display
            (if (is-eq (get curator display) tx-sender)
                (begin
                    (map-delete gallery-exhibit { art-id: art-id })
                    (ok true)
                )
                ERR-NOT-CURATOR
            )
            ERR-NOT-ON-EXHIBIT
        )
    )
)

(define-public (purchase-art (art-id uint))
    (let (
        (display-info (fetch-exhibit art-id))
        (art-info (fetch-art art-id))
    )
        (match display-info
            exhibit
            (match art-info
                artwork
                (if (and
                    (get on-display exhibit)
                    (is-eq (get artist artwork) (get curator exhibit))
                )
                    (let (
                        (amount (get asking-price exhibit))
                        (curator (get curator exhibit))
                        (commission (compute-commission amount))
                        (payout (- amount commission))
                    )
                        (begin
                            ;; Transfer STX to curator
                            (try! (stx-transfer? payout tx-sender curator))
                            ;; Transfer commission to gallery owner
                            (try! (stx-transfer? commission tx-sender (var-get gallery-owner)))
                            ;; Transfer art ownership
                            (map-set artworks
                                { art-id: art-id }
                                (merge artwork { artist: tx-sender })
                            )
                            ;; Remove from exhibit
                            (map-delete gallery-exhibit { art-id: art-id })
                            (ok true)
                        )
                    )
                    ERR-NOT-ON-EXHIBIT
                )
                ERR-ART-NOT-FOUND
            )
            ERR-NOT-ON-EXHIBIT
        )
    )
)

;; Admin Functions
(define-public (adjust-commission (new-rate uint))
    (begin
        (asserts! (is-gallery-owner) ERR-NOT-CURATOR)
        (asserts! (<= new-rate u1000) ERR-INVALID-AMOUNT)
        (var-set commission-rate new-rate)
        (ok true)
    )
)

(define-public (change-gallery-owner (new-owner principal))
    (begin
        (asserts! (is-gallery-owner) ERR-NOT-CURATOR)
        (var-set gallery-owner new-owner)
        (ok true)
    )
)
