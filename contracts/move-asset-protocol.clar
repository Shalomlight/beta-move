;; move-asset-protocol
;; Decentralized platform for registering, trading, and managing digital assets
;; across immersive digital environments with enhanced provenance tracking.

;; Core Error Constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-RESOURCE-MISSING (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INSUFFICIENT-PERMISSIONS (err u103))
(define-constant ERR-TRANSACTION-INVALID (err u104))
(define-constant ERR-METADATA-CONSTRAINT (err u105))
(define-constant ERR-ECONOMIC-CONSTRAINT (err u106))

;; Global Asset Management Variables
(define-data-var total-asset-count uint u0)

;; Asset Registration Mapping
(define-map digital-assets
  { asset-id: uint }
  {
    owner: principal,
    creator: principal,
    resource-uri: (string-utf8 256),
    transferable: bool,
    royalty-rate: uint,
    mint-block: uint,
  }
)

;; Extended Asset Metadata
(define-map asset-descriptors
  { asset-id: uint }
  {
    title: (string-utf8 100),
    description: (string-utf8 500),
    spatial-dimensions: {
      width: uint,
      height: uint,
      depth: uint,
    },
    compatible-platforms: (list 20 (string-utf8 50)),
    content-classification: (string-utf8 20),
    file-format: (string-utf8 20),
  }
)

;; Marketplace Listing Tracking
(define-map market-listings
  { asset-id: uint }
  {
    price: uint,
    lister: principal,
    list-timestamp: uint,
  }
)

;; Transfer History Tracking
(define-map transfer-ledger
  { asset-id: uint }
  { 
    history: (list 10 {
      from: principal,
      to: principal,
      transaction-value: (optional uint),
      block-height: uint,
      transaction-id: (buff 32),
    }) 
  }
)

;; Private Utility Functions
(define-private (increment-asset-counter)
  (let ((current-count (var-get total-asset-count)))
    (var-set total-asset-count (+ current-count u1))
    current-count
  )
)

(define-private (compute-royalty-payment 
    (sale-price uint)
    (royalty-rate uint)
  )
  (/ (* sale-price royalty-rate) u1000)
)

;; Read-Only Query Functions
(define-read-only (get-asset-details (asset-id uint))
  (map-get? digital-assets { asset-id: asset-id })
)

(define-read-only (get-asset-metadata (asset-id uint))
  (map-get? asset-descriptors { asset-id: asset-id })
)

(define-read-only (check-asset-listing (asset-id uint))
  (map-get? market-listings { asset-id: asset-id })
)

(define-read-only (get-transfer-provenance (asset-id uint))
  (default-to { history: (list) }
    (map-get? transfer-ledger { asset-id: asset-id })
  )
)

;; Public Asset Management Functions
(define-public (mint-digital-asset
    (resource-uri (string-utf8 256))
    (title (string-utf8 100))
    (description (string-utf8 500))
    (spatial-dimensions {
      width: uint,
      height: uint,
      depth: uint,
    })
    (compatible-platforms (list 20 (string-utf8 50)))
    (content-classification (string-utf8 20))
    (file-format (string-utf8 20))
    (transferable bool)
    (royalty-rate uint)
  )
  (let (
      (asset-id (increment-asset-counter))
      (creator tx-sender)
    )
    ;; Validate input constraints
    (asserts! (<= (len resource-uri) u256) ERR-METADATA-CONSTRAINT)
    (asserts! (<= royalty-rate u500) ERR-ECONOMIC-CONSTRAINT)

    ;; Persist primary asset record
    (map-set digital-assets { asset-id: asset-id } {
      owner: creator,
      creator: creator,
      resource-uri: resource-uri,
      transferable: transferable,
      royalty-rate: royalty-rate,
      mint-block: block-height,
    })

    ;; Store comprehensive metadata
    (map-set asset-descriptors { asset-id: asset-id } {
      title: title,
      description: description,
      spatial-dimensions: spatial-dimensions,
      compatible-platforms: compatible-platforms,
      content-classification: content-classification,
      file-format: file-format,
    })

    (ok asset-id)
  )
)

(define-public (transfer-asset-ownership
    (asset-id uint)
    (new-owner principal)
  )
  (let (
      (asset-info (unwrap! (map-get? digital-assets { asset-id: asset-id }) ERR-RESOURCE-MISSING))
    )
    ;; Ownership and transferability validation
    (asserts! (is-eq tx-sender (get owner asset-info)) ERR-INSUFFICIENT-PERMISSIONS)
    (asserts! (get transferable asset-info) ERR-UNAUTHORIZED)

    ;; Remove any existing marketplace listing
    (map-delete market-listings { asset-id: asset-id })

    ;; Update asset ownership
    (map-set digital-assets { asset-id: asset-id }
      (merge asset-info { owner: new-owner })
    )

    (ok true)
  )
)

;; More contract functions would follow... 