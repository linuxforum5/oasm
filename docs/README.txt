IF ( ... ) {
} else if ( ... ) {
} else {
}
    Ha az első IF nagy, akkor JP, ha kicsi, akkor JR az ágak között

DEC|INC property_1_byte_length
    Ha a DEC|INC nagybetűs, akko LD HL, ... és INC (HL) a kifejtése (31 T ciklus 5 byte), ha kisbetűs, akkor LD A, (...), INC A, LD (...), A a kifejtése (30 T ciklus, de 7 byte)

{
    ...
} until () ; Forever loop

while() { ; Ez is forever loop, még nem teszteltem
}
