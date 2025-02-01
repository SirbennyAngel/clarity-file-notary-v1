;; File Notary Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))
(define-constant err-invalid-batch (err u103))

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

;; Data vars
(define-data-var next-batch-id uint u1)

;; Public Functions
(define-public (register-file (file-hash (buff 32)) (description (string-ascii 256)))
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
                (ok true)
            )
        )
    )
)

(define-public (register-batch 
    (file-hashes (list 200 (buff 32))) 
    (descriptions (list 200 (string-ascii 256)))
    (batch-description (string-ascii 256))
)
    (let (
        (batch-id (var-get next-batch-id))
        (file-count (len file-hashes))
    )
        (asserts! (> file-count u0) err-invalid-batch)
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
        (ok batch-id)
    )
)

(define-private (register-batch-file (params (tuple (hash (buff 32)) (desc (string-ascii 256)) (batch uint))))
    (map-set file-records
        { hash: (get hash params) }
        {
            owner: tx-sender,
            timestamp: block-height,
            description: (get desc params),
            is-verified: false,
            batch-id: (some (get batch params))
        }
    )
)

(define-public (verify-batch (batch-id uint))
    (if (is-eq tx-sender contract-owner)
        (let ((batch (get-batch-record batch-id)))
            (match batch
                record (begin
                    (verify-all-files-in-batch batch-id)
                    (ok true)
                )
                err-not-found
            )
        )
        err-not-owner
    )
)

(define-private (verify-all-files-in-batch (batch-id uint))
    (map verify-if-in-batch (keys file-records))
)

(define-private (verify-if-in-batch (key {hash: (buff 32)}))
    (let ((record (get-file-record (get hash key))))
        (match record
            file-record (begin
                (if (is-eq (get batch-id file-record) batch-id)
                    (map-set file-records
                        key
                        (merge file-record { is-verified: true })
                    )
                    false
                )
            )
            false
        )
    )
)

(define-public (verify-file (file-hash (buff 32)))
    (if (is-eq tx-sender contract-owner)
        (match (get-file-record file-hash)
            record (begin
                (map-set file-records
                    { hash: file-hash }
                    (merge record { is-verified: true })
                )
                (ok true)
            )
            err-not-found
        )
        err-not-owner
    )
)

(define-public (transfer-ownership (file-hash (buff 32)) (new-owner principal))
    (match (get-file-record file-hash)
        record (begin
            (asserts! (is-eq (get owner record) tx-sender) err-not-owner)
            (map-set file-records
                { hash: file-hash }
                (merge record { owner: new-owner })
            )
            (ok true)
        )
        err-not-found
    )
)

;; Read Only Functions
(define-read-only (get-file-record (file-hash (buff 32)))
    (map-get? file-records { hash: file-hash })
)

(define-read-only (get-batch-record (batch-id uint))
    (map-get? batch-records { batch-id: batch-id })
)

(define-read-only (is-file-verified (file-hash (buff 32)))
    (match (get-file-record file-hash)
        record (ok (get is-verified record))
        (ok false)
    )
)

(define-read-only (get-file-owner (file-hash (buff 32)))
    (match (get-file-record file-hash)
        record (ok (get owner record))
        err-not-found
    )
)
