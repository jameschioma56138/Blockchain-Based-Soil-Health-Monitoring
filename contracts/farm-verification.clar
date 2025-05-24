;; Farm Verification Contract
;; Validates and manages agricultural operations

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-FARM-NOT-FOUND (err u101))
(define-constant ERR-FARM-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-COORDINATES (err u103))

(define-data-var contract-owner principal tx-sender)

;; Farm data structure
(define-map farms
  { farm-id: uint }
  {
    owner: principal,
    location: { latitude: int, longitude: int },
    size-hectares: uint,
    registration-date: uint,
    verified: bool,
    farm-type: (string-ascii 50)
  }
)

(define-data-var next-farm-id uint u1)

;; Register a new farm
(define-public (register-farm (latitude int) (longitude int) (size-hectares uint) (farm-type (string-ascii 50)))
  (let ((farm-id (var-get next-farm-id)))
    (asserts! (and (>= latitude -90000000) (<= latitude 90000000)) ERR-INVALID-COORDINATES)
    (asserts! (and (>= longitude -180000000) (<= longitude 180000000)) ERR-INVALID-COORDINATES)
    (asserts! (> size-hectares u0) ERR-INVALID-COORDINATES)

    (map-set farms
      { farm-id: farm-id }
      {
        owner: tx-sender,
        location: { latitude: latitude, longitude: longitude },
        size-hectares: size-hectares,
        registration-date: block-height,
        verified: false,
        farm-type: farm-type
      }
    )
    (var-set next-farm-id (+ farm-id u1))
    (ok farm-id)
  )
)

;; Verify a farm (only contract owner)
(define-public (verify-farm (farm-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (match (map-get? farms { farm-id: farm-id })
      farm-data (begin
        (map-set farms
          { farm-id: farm-id }
          (merge farm-data { verified: true })
        )
        (ok true)
      )
      ERR-FARM-NOT-FOUND
    )
  )
)

;; Get farm details
(define-read-only (get-farm (farm-id uint))
  (map-get? farms { farm-id: farm-id })
)

;; Check if farm is verified
(define-read-only (is-farm-verified (farm-id uint))
  (match (map-get? farms { farm-id: farm-id })
    farm-data (ok (get verified farm-data))
    ERR-FARM-NOT-FOUND
  )
)

;; Get farm owner
(define-read-only (get-farm-owner (farm-id uint))
  (match (map-get? farms { farm-id: farm-id })
    farm-data (ok (get owner farm-data))
    ERR-FARM-NOT-FOUND
  )
)
