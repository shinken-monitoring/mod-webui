
function processMetric(m) {
    str = "";

    if ( m.value ) str = str + m.value;
    if ( m.uom ) str = str +  " " + m.uom;

    if ( m.critical && m.value > m.critical ) str = '<span style="color: red">' + str + '<span>';
    else if ( m.warning && m.value > m.warning ) str = '<span style="color: orange">' + str + '<span>';
    else  str = '<span style="color: green">' + str + '<span>';

    return str

}
