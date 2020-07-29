fs = require 'fs'

module.exports =
  initPdfa: ->
    @_uuid = null

  pdfaMetadata: ()->
    ref = @ref
      Type: 'Metadata'
      Subtype: 'XML',
      { compress: false }
    ref.write(@pdfaXMP())
    ref

  pdfaOutputIntents: ()->
    ref = @ref
      Type: 'OutputIntent'
      S: 'GTS_PDFA1'
      Info: new String('sRGB IEC61966-2.1')
      OutputConditionIdentifier: new String('sRGB IEC61966-2.1')
      DestOutputProfile: @destOutputProfile()
    [ref]

  destOutputProfile: ->
    ref = @ref
      N: 3
    ref.write(sRGB_IEC61966_ICC_PROFILE())
    ref

  #
  # http://www.iso.org/iso/home/store/catalogue_tc/catalogue_detail.htm?csnumber=38920
  # http://www.aiim.org/documents/standards/pdf/xmp_specification.pdf
  #
  pdfaXMP: ->
    s =  '<?xpacket begin="\xEF\xBB\xBF" id="W5M0MpCehiHzreSzNTczkc9d"?>' + "\n" # "begin=" contains UTF-8 BOM (U+FEFF)
    s += '  <x:xmpmeta xmlns:x="adobe:ns:meta/">' + "\n"
    s += '    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">' + "\n"

    s += '      <rdf:Description rdf:about="uuid:' + @fileIdentifier() + '" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">' + "\n"
    s += '        <pdf:Producer>' + @info.Producer + '</pdf:Producer>' + "\n"
    s += '        <pdf:Keywords>' + @info.Keywords + '</pdf:Keywords>' + "\n" if @info.Keywords
    s += '      </rdf:Description>' + "\n"

    s += '      <rdf:Description rdf:about="uuid:' + @fileIdentifier() + '" xmlns:xmp="http://ns.adobe.com/xap/1.0/">' + "\n"
    s += '        <xmp:CreateDate>' + @info.CreationDate.toISOString() + '</xmp:CreateDate>' + "\n"
    s += '        <xmp:ModifyDate>' + @info.CreationDate.toISOString() + '</xmp:ModifyDate>' + "\n"
    s += '        <xmp:MetadataDate>' + @info.CreationDate.toISOString() + '</xmp:MetadataDate>' + "\n"
    s += '        <xmp:CreatorTool>' + @info.Creator + '</xmp:CreatorTool>' + "\n";
    s += '      </rdf:Description>' + "\n";

    s += '      <rdf:Description rdf:about="uuid:' + @fileIdentifier() + '" xmlns:dc="http://purl.org/dc/elements/1.1/">' + "\n"
    s += '        <dc:title><rdf:Alt><rdf:li xml:lang="x-default">' + @info.Title + '</rdf:li></rdf:Alt></dc:title>' + "\n" if @info.Title
    s += '        <dc:subject><rdf:Bag><rdf:li>' + @info.Subject + '</rdf:li></rdf:Bag></dc:subject>' + "\n" if @info.Subject
    s += '        <dc:creator><rdf:Seq><rdf:li>' + @info.Author + '</rdf:li></rdf:Seq></dc:creator>' + "\n" if @info.Author
    s += '      </rdf:Description>' + "\n"

    s += '      <rdf:Description rdf:about="uuid:' + @fileIdentifier() + '" xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/" >' + "\n"
    s += '        <pdfaid:part>3</pdfaid:part>' + "\n"
    s += '        <pdfaid:conformance>B</pdfaid:conformance>' + "\n"
    #s += '        <pdfaid:amd>2005</pdfaid:amd>' + "\n"
    s += '      </rdf:Description>' + "\n"

    s += '      <rdf:Description rdf:about="uuid:' + @fileIdentifier() + '" xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/">' + "\n"
    s += '        <xmpMM:DocumentID>uuid:' + @fileIdentifier() + '</xmpMM:DocumentID>' + "\n"
    s += '      </rdf:Description>' + "\n"

    s += @addRdfAbout(@options.pdfaAdditionalXmpRdf) + "\n" if @options.pdfaAdditionalXmpRdf # optionally given rdf

    s += '    </rdf:RDF>' + "\n";
    s += '  </x:xmpmeta>' + "\n";
    s += '<?xpacket end="w"?>';
    return s

  addRdfAbout: (rdf) ->
    rdf.replace(/\<rdf:Description/g, '<rdf:Description rdf:about="uuid:' + @fileIdentifier() + '"')

sRGB_IEC61966_ICC_PROFILE = ->
  Buffer "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", "base64"