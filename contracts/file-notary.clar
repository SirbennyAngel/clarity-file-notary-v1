;; File Notary Contract - Enhanced Version

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))
(define-constant err-invalid-batch (err u103))
(define-constant err-empty-input (err u104))
(define-constant err-contract-paused (err u105))
(define-constant err-rate-limit (err u106))
(define-constant max-batch-size u200)

;; Data vars
(define-data-var next-batch-id uint u1)
(define-data-var contract-paused bool false)
(define-data-var rate-limit-counter uint u0)
(define-data-var rate-limit-timestamp uint u0)

;; Enhanced Data Maps
(define-map file-records
    { hash: (buff 32) }
    {
        owner: principal,
        timestamp: uint,
        description: (string-ascii 256),
        is-verified: bool,
        batch-id: (optional uint),
        history: (list 20 {
            action: (string-ascii 20),
            actor: principal,
            timestamp: uint
        })
    }
)

(define-map batch-records
    { batch-id: uint }
    {
        owner: principal,
        timestamp: uint,
        description: (string-ascii 256),
        file-count: uint,
        status: (string-ascii 20)
    }
)

;; Enhanced Events
(define-data-var last-event-id uint u0)

(define-private (emit-event (event-type (string-ascii 20)) (data (buff 32)) (metadata (optional (string-ascii 256))))
    (begin
        (var-set last-event-id (+ (var-get last-event-id) u1))
        (print {
            event-id: (var-get last-event-id),
            type: event-type,
            data: data,
            metadata: metadata
        })
    )
)

;; Rate Limiting
(define-private (check-rate-limit)
    (let (
        (current-height block-height)
        (last-timestamp (var-get rate-limit-timestamp))
    )
        (if (> (- current-height last-timestamp) u100)
            (begin
                (var-set rate-limit-counter u1)
                (var-set rate-limit-timestamp current-height)
                true
            )
            (if (< (var-get rate-limit-counter) u10)
                (begin
                    (var-set rate-limit-counter (+ (var-get rate-limit-counter) u1))
                    true
                )
                false
            )
        )
    )
)

;; Enhanced Public Functions
(define-public (register-file (file-hash (buff 32)) (description (string-ascii 256)))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (asserts! (check-rate-limit) err-rate-limit)
        (try! (validate-input description))
        (let ((existing-record (get-file-record file-hash)))
            (match existing-record
                success err-already-exists
                failure (begin
                    (map-set file-records
                        { hash: file-hash }
                        {
                            owner: tx-sender,
                            timestamp: block-height,
                            description: description,
                            is-verified: false,
                            batch-id: none,
                            history: (list
                                {
                                    action: "REGISTERED",
                                    actor: tx-sender,
                                    timestamp: block-height
                                }
                            )
                        }
                    )
                    (emit-event "FILE_REGISTERED" file-hash (some description))
                    (ok true)
                ))
            )
        )
    )
)

;; New Query Functions
(define-read-only (get-file-history (file-hash (buff 32)))
    (match (map-get? file-records { hash: file-hash })
        record (ok (get history record))
        (err err-not-found)
    )
)

(define-read-only (get-batch-status (batch-id uint))
    (match (map-get? batch-records { batch-id: batch-id })
        record (ok (get status record))
        (err err-not-found)
    )
)

;; [Previous functions remain with similar enhancements]
