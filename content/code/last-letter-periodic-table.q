begin:{
    updateSeed[];
    .game.elements: `hydrogen`helium`lithium`beryllium`boron`carbon`nitrogen`oxygen`fluorine`neon`sodium`magnesium`aluminium`silicon`phosphorus`sulfur`chlorine`argon`potassium`calcium`scandium`titanium`vanadium`chromium`manganese`iron`cobalt`nickel`copper`zinc`gallium`germanium`arsenic`selenium`bromine`krypton`rubidium`strontium`yttrium`zirconium`niob`molybdenum`technetium`ruthenium`rhodium`palladium`silver`cadmium`indium`tin`antimony`tellerium`iodine`xenon`caesium`barium`lanthanum`cerium`praesodym`neodym`promethium`samarium`europium`gadolinium`terbium`dysprosium`holmium`erbium`thulium`ytterbium`lutetium`hafnium`tantalum`tungsten`rhenium`osmium`iridium`platinum`gold`mercury`thallium`lead`bismuth`polonium`astatine`radon`francium`radium`actinium`thorium`protactinium`uranium`neptunium`plutonium`americium`curium`berkelium`californium`einsteinium`fermium`mendelevium`nobelium`lawrencium`rutherfordium`dubnium`seaborgium`bohrium`hassium`meitnerium`darmstadtium`roentgenium`copernicium`nihonium`flerovium`moscovium`livermorium`tenessine`oganesson; 
    :pick[]
 };

pick:{
    .game.picked: rand .game.elements;
    .game.elements: remove[.game.picked];
    $[isWin[];
        "I pick", (string .game.picked), ". There is no element left that begins with ", (last string .game.picked), ". I win!";
        "I pick ", string .game.picked
    ]
 };

isWin:{
    :`=findLast[.game.picked];
 };

pickNext:{[element] 
    .game.picked: element;
    .game.elements: remove[element];
    $[isWin[];
        "I pick ", (string .game.picked), ". There is no element left that begins with ", (last string .game.picked), ". I win!";
        "I pick ", string .game.picked
    ]
 };

remove:{[element] 
    :.game.elements[where .game.elements<>element]
 };

turn:{[element] 
    elementSymbol:`$element;
    $[isValidChoice elementSymbol;
        [
            .game.elements: remove[elementSymbol];
            n:findLast[elementSymbol];
            $[`=n;
                message:"I can't find any element that begins with ", (last element), ". You win!";
                message:pickNext[n]
            ];
        ]; 
        message:"Please pick an element that starts with ",(last string .game.picked), "."
    ];
    :message;
 };

isValidChoice:{[element] 
    :((last string .game.picked)=first string element) & element in .game.elements
 };

findLast:{[element] 
    lastLetter:last string element;
    :rand .game.elements[where (string .game.elements) like lastLetter,"*"]
 };

updateSeed:{
    system "S ",string "i"$.z.T;
 };

begin[]