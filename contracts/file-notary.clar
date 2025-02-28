;; File Notary Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))
(define-constant err-invalid-batch (err u103))
(define-constant err-empty-input (err u104))
(define-constant err-contract-paused (err u105))
(define-constant max-batch-size u200)

;; Data vars
(define-data-var next-batch-id uint u1)
(define-data-var contract-paused bool false)

;; Data Maps
(define-map file-records
    { hash: (buff 32) }
    {
        owner: principal,
        timestamp: uint,
        description: (string-ascii 256),
        is-verified: bool,
        batch-id: (optional uint)
    }
)

(define-map batch-records
    { batch-id: uint }
    {
        owner: principal,
        timestamp: uint,
        description: (string-ascii 256),
        file-count: uint
    }
)

;; Events
(define-data-var last-event-id uint u0)

(define-private (emit-event (event-type (string-ascii 20)) (data (buff 32)))
    (begin
        (var-set last-event-id (+ (var-get last-event-id) u1))
        (print { event-id: (var-get last-event-id), type: event-type, data: data })
    )
)

;; Admin Functions
(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-not-owner)
        (ok (var-set contract-paused (not (var-get contract-paused))))
    )
)

;; Helper Functions
(define-private (validate-input (description (string-ascii 256)))
    (ok (asserts! (> (len description) u0) err-empty-input))
)

;; Public Functions
(define-public (register-file (file-hash (buff 32)) (description (string-ascii 256)))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
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
                            batch-id: none
                        }
                    )
                    (emit-event "FILE_REGISTERED" file-hash)
                    (ok true)
                )
            )
        )
    )
)

(define-public (register-batch 
    (file-hashes (list 200 (buff 32))) 
    (descriptions (list 200 (string-ascii 256)))
    (batch-description (string-ascii 256))
)
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (try! (validate-input batch-description))
        (let (
            (batch-id (var-get next-batch-id))
            (file-count (len file-hashes))
        )
            (asserts! (and (> file-count u0) (<= file-count max-batch-size)) err-invalid-batch)
            (asserts! (is-eq (len file-hashes) (len descriptions)) err-invalid-batch)
            
            (map-set batch-records
                { batch-id: batch-id }
                {
                    owner: tx-sender,
                    timestamp: block-height,
                    description: batch-description,
                    file-count: file-count
                }
            )
            
            (map register-batch-file (zip file-hashes descriptions (list file-count batch-id)))
            
            (var-set next-batch-id (+ batch-id u1))
            (emit-event "BATCH_REGISTERED" (to-buff batch-id))
            (ok batch-id)
        )
    )
)

;; [Rest of the contract functions remain the same but with added event emissions]
