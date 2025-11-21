
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_TOURNAMENT_NOT_FOUND (err u2))
(define-constant ERR_TOURNAMENT_ACTIVE (err u3))
(define-constant ERR_TOURNAMENT_ENDED (err u4))
(define-constant ERR_INSUFFICIENT_FUNDS (err u5))
(define-constant ERR_ALREADY_PAID (err u6))
(define-constant ERR_INVALID_WINNER (err u7))
(define-constant ERR_TOURNAMENT_NOT_ENDED (err u8))
(define-constant ERR_INVALID_PRIZE_STRUCTURE (err u9))
(define-constant ERR_PAYOUT_FAILED (err u10))
(define-constant ERR_INVALID_AMOUNT (err u11))
(define-constant ERR_SPONSORSHIP_DISABLED (err u12))

(define-data-var next-tournament-id uint u1)
(define-map tournaments uint {
    name: (string-ascii 64),
    organizer: principal,
    prize-pool: uint,
    entry-fee: uint,
    max-participants: uint,
    current-participants: uint,
    start-block: uint,
    end-block: uint,
    status: (string-ascii 16),
    winner-verified: bool,
    prize-distributed: bool
})

(define-map participants { tournament-id: uint, participant: principal } {
    entry-paid: bool,
    eliminated: bool,
    final-position: uint
})

(define-map tournament-winners uint {
    first-place: principal,
    second-place: principal,
    third-place: principal,
    first-prize: uint,
    second-prize: uint,
    third-prize: uint
})

(define-map tournament-balances uint uint)

(define-map player-stats principal {
    total-tournaments: uint,
    first-place-count: uint,
    second-place-count: uint,
    third-place-count: uint,
    total-winnings: uint,
    reputation-score: uint
})

(define-map tournament-sponsors { tournament-id: uint, sponsor: principal } {
    amount: uint,
    timestamp: uint
})

(define-map sponsor-stats principal {
    total-sponsored: uint,
    tournaments-sponsored: uint,
    sponsor-reputation: uint
})

(define-public (create-tournament 
    (name (string-ascii 64))
    (entry-fee uint)
    (max-participants uint)
    (duration-blocks uint)
    (first-prize-percent uint)
    (second-prize-percent uint)
    (third-prize-percent uint))
    (let (
        (tournament-id (var-get next-tournament-id))
        (start-block stacks-block-height)
        (end-block (+ stacks-block-height duration-blocks))
    )
    (asserts! (and 
        (> max-participants u2)
        (> entry-fee u0)
        (> duration-blocks u0)
        (is-eq (+ first-prize-percent second-prize-percent third-prize-percent) u100)
    ) ERR_INVALID_PRIZE_STRUCTURE)
    
    (map-set tournaments tournament-id {
        name: name,
        organizer: tx-sender,
        prize-pool: u0,
        entry-fee: entry-fee,
        max-participants: max-participants,
        current-participants: u0,
        start-block: start-block,
        end-block: end-block,
        status: "registration",
        winner-verified: false,
        prize-distributed: false
    })
    
    (map-set tournament-balances tournament-id u0)
    (var-set next-tournament-id (+ tournament-id u1))
    (ok tournament-id)
    )
)

(define-public (register-participant (tournament-id uint))
    (let (
        (tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND))
        (current-participants (get current-participants tournament))
        (entry-fee (get entry-fee tournament))
        (tournament-balance (default-to u0 (map-get? tournament-balances tournament-id)))
    )
    (asserts! (is-eq (get status tournament) "registration") ERR_TOURNAMENT_ACTIVE)
    (asserts! (< current-participants (get max-participants tournament)) ERR_TOURNAMENT_ACTIVE)
    (asserts! (is-none (map-get? participants { tournament-id: tournament-id, participant: tx-sender })) ERR_TOURNAMENT_ACTIVE)
    
    (try! (stx-transfer? entry-fee tx-sender (as-contract tx-sender)))
    
    (map-set participants { tournament-id: tournament-id, participant: tx-sender } {
        entry-paid: true,
        eliminated: false,
        final-position: u0
    })
    
    (map-set tournaments tournament-id (merge tournament {
        current-participants: (+ current-participants u1),
        prize-pool: (+ (get prize-pool tournament) entry-fee)
    }))
    
    (map-set tournament-balances tournament-id (+ tournament-balance entry-fee))
    (ok true)
    )
)

(define-public (start-tournament (tournament-id uint))
    (let (
        (tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get organizer tournament)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status tournament) "registration") ERR_TOURNAMENT_ACTIVE)
    (asserts! (>= (get current-participants tournament) u3) ERR_TOURNAMENT_ACTIVE)
    
    (map-set tournaments tournament-id (merge tournament {
        status: "active"
    }))
    (ok true)
    )
)

(define-public (end-tournament (tournament-id uint))
    (let (
        (tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get organizer tournament)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status tournament) "active") ERR_TOURNAMENT_NOT_ENDED)
    (asserts! (>= stacks-block-height (get end-block tournament)) ERR_TOURNAMENT_NOT_ENDED)
    
    (map-set tournaments tournament-id (merge tournament {
        status: "ended"
    }))
    (ok true)
    )
)

(define-public (verify-winners 
    (tournament-id uint)
    (first-place principal)
    (second-place principal)
    (third-place principal))
    (let (
        (tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND))
        (prize-pool (get prize-pool tournament))
        (first-prize (/ (* prize-pool u50) u100))
        (second-prize (/ (* prize-pool u30) u100))
        (third-prize (/ (* prize-pool u20) u100))
    )
    (asserts! (is-eq tx-sender (get organizer tournament)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status tournament) "ended") ERR_TOURNAMENT_NOT_ENDED)
    (asserts! (not (get winner-verified tournament)) ERR_ALREADY_PAID)
    
    (asserts! (is-some (map-get? participants { tournament-id: tournament-id, participant: first-place })) ERR_INVALID_WINNER)
    (asserts! (is-some (map-get? participants { tournament-id: tournament-id, participant: second-place })) ERR_INVALID_WINNER)
    (asserts! (is-some (map-get? participants { tournament-id: tournament-id, participant: third-place })) ERR_INVALID_WINNER)
    
    (map-set tournament-winners tournament-id {
        first-place: first-place,
        second-place: second-place,
        third-place: third-place,
        first-prize: first-prize,
        second-prize: second-prize,
        third-prize: third-prize
    })
    
    (map-set participants { tournament-id: tournament-id, participant: first-place } 
        (merge (default-to { entry-paid: true, eliminated: false, final-position: u0 } 
            (map-get? participants { tournament-id: tournament-id, participant: first-place })) 
            { final-position: u1 }))
    
    (map-set participants { tournament-id: tournament-id, participant: second-place } 
        (merge (default-to { entry-paid: true, eliminated: false, final-position: u0 } 
            (map-get? participants { tournament-id: tournament-id, participant: second-place })) 
            { final-position: u2 }))
    
    (map-set participants { tournament-id: tournament-id, participant: third-place } 
        (merge (default-to { entry-paid: true, eliminated: false, final-position: u0 } 
            (map-get? participants { tournament-id: tournament-id, participant: third-place })) 
            { final-position: u3 }))
    
    (map-set tournaments tournament-id (merge tournament {
        winner-verified: true
    }))
    (ok true)
    )
)

(define-public (distribute-prizes (tournament-id uint))
    (let (
        (tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND))
        (winners (unwrap! (map-get? tournament-winners tournament-id) ERR_INVALID_WINNER))
    )
    (asserts! (get winner-verified tournament) ERR_TOURNAMENT_NOT_ENDED)
    (asserts! (not (get prize-distributed tournament)) ERR_ALREADY_PAID)
    
    (try! (as-contract (stx-transfer? (get first-prize winners) tx-sender (get first-place winners))))
    (try! (as-contract (stx-transfer? (get second-prize winners) tx-sender (get second-place winners))))
    (try! (as-contract (stx-transfer? (get third-prize winners) tx-sender (get third-place winners))))
    
    (update-player-stats (get first-place winners) u1 (get first-prize winners))
    (update-player-stats (get second-place winners) u2 (get second-prize winners))
    (update-player-stats (get third-place winners) u3 (get third-prize winners))
    
    (map-set tournaments tournament-id (merge tournament {
        prize-distributed: true,
        status: "completed"
    }))
    
    (map-set tournament-balances tournament-id u0)
    (ok true)
    )
)

(define-public (emergency-withdraw (tournament-id uint))
    (let (
        (tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND))
        (balance (default-to u0 (map-get? tournament-balances tournament-id)))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> balance u0) ERR_INSUFFICIENT_FUNDS)
    
    (try! (as-contract (stx-transfer? balance tx-sender CONTRACT_OWNER)))
    (map-set tournament-balances tournament-id u0)
    (ok balance)
    )
)

(define-read-only (get-tournament (tournament-id uint))
    (map-get? tournaments tournament-id)
)

(define-read-only (get-participant-info (tournament-id uint) (participant principal))
    (map-get? participants { tournament-id: tournament-id, participant: participant })
)

(define-read-only (get-tournament-winners (tournament-id uint))
    (map-get? tournament-winners tournament-id)
)

(define-read-only (get-tournament-balance (tournament-id uint))
    (default-to u0 (map-get? tournament-balances tournament-id))
)

(define-read-only (get-next-tournament-id)
    (var-get next-tournament-id)
)

(define-read-only (is-tournament-active (tournament-id uint))
    (match (map-get? tournaments tournament-id)
        tournament (is-eq (get status tournament) "active")
        false
    )
)

(define-read-only (can-register (tournament-id uint))
    (match (map-get? tournaments tournament-id)
        tournament (and 
            (is-eq (get status tournament) "registration")
            (< (get current-participants tournament) (get max-participants tournament))
        )
        false
    )
)

(define-private (update-player-stats (player principal) (position uint) (winnings uint))
    (let (
        (current-stats (default-to 
            { total-tournaments: u0, first-place-count: u0, second-place-count: u0, 
              third-place-count: u0, total-winnings: u0, reputation-score: u0 }
            (map-get? player-stats player)))
        (new-first (if (is-eq position u1) (+ (get first-place-count current-stats) u1) (get first-place-count current-stats)))
        (new-second (if (is-eq position u2) (+ (get second-place-count current-stats) u1) (get second-place-count current-stats)))
        (new-third (if (is-eq position u3) (+ (get third-place-count current-stats) u1) (get third-place-count current-stats)))
        (position-points (if (is-eq position u1) u100 (if (is-eq position u2) u50 u25)))
    )
    (map-set player-stats player {
        total-tournaments: (+ (get total-tournaments current-stats) u1),
        first-place-count: new-first,
        second-place-count: new-second,
        third-place-count: new-third,
        total-winnings: (+ (get total-winnings current-stats) winnings),
        reputation-score: (+ (get reputation-score current-stats) position-points)
    })
    true
    )
)

(define-read-only (get-player-stats (player principal))
    (map-get? player-stats player)
)

(define-read-only (get-player-reputation (player principal))
    (match (map-get? player-stats player)
        stats (get reputation-score stats)
        u0
    )
)

(define-public (sponsor-tournament (tournament-id uint) (amount uint))
    (let (
        (tournament (unwrap! (map-get? tournaments tournament-id) ERR_TOURNAMENT_NOT_FOUND))
        (tournament-balance (default-to u0 (map-get? tournament-balances tournament-id)))
        (current-sponsor-stats (default-to 
            { total-sponsored: u0, tournaments-sponsored: u0, sponsor-reputation: u0 }
            (map-get? sponsor-stats tx-sender)))
        (existing-sponsorship (map-get? tournament-sponsors { tournament-id: tournament-id, sponsor: tx-sender }))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (or 
        (is-eq (get status tournament) "registration")
        (is-eq (get status tournament) "active")
    ) ERR_TOURNAMENT_ENDED)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (match existing-sponsorship
        prev-sponsorship
            (map-set tournament-sponsors { tournament-id: tournament-id, sponsor: tx-sender } {
                amount: (+ (get amount prev-sponsorship) amount),
                timestamp: stacks-block-height
            })
        (begin
            (map-set tournament-sponsors { tournament-id: tournament-id, sponsor: tx-sender } {
                amount: amount,
                timestamp: stacks-block-height
            })
            (map-set sponsor-stats tx-sender {
                total-sponsored: (+ (get total-sponsored current-sponsor-stats) amount),
                tournaments-sponsored: (+ (get tournaments-sponsored current-sponsor-stats) u1),
                sponsor-reputation: (+ (get sponsor-reputation current-sponsor-stats) (/ amount u1000))
            })
        )
    )
    
    (map-set tournaments tournament-id (merge tournament {
        prize-pool: (+ (get prize-pool tournament) amount)
    }))
    
    (map-set tournament-balances tournament-id (+ tournament-balance amount))
    (ok true)
    )
)

(define-read-only (get-sponsor-contribution (tournament-id uint) (sponsor principal))
    (map-get? tournament-sponsors { tournament-id: tournament-id, sponsor: sponsor })
)

(define-read-only (get-sponsor-stats (sponsor principal))
    (map-get? sponsor-stats sponsor)
)

(define-read-only (get-sponsor-reputation (sponsor principal))
    (match (map-get? sponsor-stats sponsor)
        stats (get sponsor-reputation stats)
        u0
    )
)

