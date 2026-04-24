function __fishblood_arrow --description "Map a Nightscout direction string to a unicode arrow"
    switch "$argv[1]"
        case DoubleUp
            echo ⇈
        case SingleUp
            echo ↑
        case FortyFiveUp
            echo ↗
        case Flat
            echo →
        case FortyFiveDown
            echo ↘
        case SingleDown
            echo ↓
        case DoubleDown
            echo ⇊
        case '*'
            # NONE, NOT COMPUTABLE, RATE OUT OF RANGE, empty, etc.
            echo ''
    end
end
