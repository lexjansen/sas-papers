PROC GROOVY;
SUBMIT;

String xmldocument = '''

<singles>
  <entry rank="67" year="1954">
    <artist>Nolan Strong and the Diablos</artist>
    <title>The wind</title>
    <writer>Nolan Strong and The Diablos</writer>
    <label>Fortune Records</label>
    <year>1954</year>
  </entry>
  <entry rank="265" year="1962">
    <artist>Nathaniel Mayer</artist>
    <title>Village of love</title>
    <writer>Nathaniel Mayer &amp; Devora Brown</writer>
    <label>Fortune Records</label>
  </entry>
  <entry rank="938" year="1963">
    <artist>Gino Washington</artist>
    <title>Gino is a coward</title>
    <writer>Ronald Davis</writer>
    <label>Ric Tic Records</label>
  </entry>
</singles>
'''

def singles = new XmlSlurper().parseText(xmldocument)
def allSingles = singles.entry.size()
println("Number of entries in the XML documents is: $allSingles")

for (e in singles.entry) {
    println "[${e.@rank}] ${e.artist} sang \"${e.title}\" (${e.@year})," +
            "\n  written by ${e.writer}, for ${e.label}."
  }

singles.entry.each() {
    println "[${it.@rank}] ${it.artist} sang \"${it.title}\" (${it.@year})," +
            "\n  written by ${it.writer}, for ${it.label}."
  }

def Fortune = "Fortune Records"
def nFortune = singles.entry.findAll {it.label == Fortune}.size()
println "\n$nFortune singles were recorded for $Fortune:"
singles.entry.findAll {it.label == Fortune}.each() {
    println "  ${it.artist} - \"${it.title}\" (${it.@year})"

  
}

ENDSUBMIT;
