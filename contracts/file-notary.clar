;; File Notary Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))

;; Data Maps
(define-map file-records
    { hash: (buff 32) }
    {
        owner: principal,
        timestamp: uint,
        description: (string-ascii 256),
        is-verified: bool
    }
)

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
                        is-verified: false
                    }
                )
                (ok true)
            )
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
