require_relative 'test_helper'

code = <<-eos
                      .--.            .---.  .---. .---.  .---.    .---.  .---. 
                      |  |   OS API   '---'  '---' '---'  '---'    '---'  '---' 
                      v  |              |      |     |      |        |      |   
             .-. .-. .-. |              v      v     |      v        |      v   
         .-->'-' '-' '-' |            .------------. | .-----------. |  .-----. 
         |     \\  |  /   |            | Filesystem | | | Scheduler | |  | MMU | 
         |      v . v    |            '------------' | '-----------' |  '-----' 
         '_______/ \\_____|                   |       |      |        |          
                 \\ /                         v       |      |        v          
                  |     ____              .----.     |      |    .---------.    
                  '--> /___/              | IO |<----'      |    | Network |    
                                          '----'            |    '---------'    
                                             |              |         |         
                                             v              v         v         
                                      .---------------------------------------. 
                                      |                  HAL                  | 
                                      '---------------------------------------'
eos

describe Asciidoctor::Diagram::AsciiToSvgBlockMacroProcessor, :broken_on_travis, :broken_on_windows do
  it "should generate SVG images when format is set to 'svg'" do
    File.write('a2s.txt', code)

    doc = <<-eos
= Hello, a2s!
Doc Writer <doc@example.com>

== First Section

a2s::a2s.txt[format="svg"]
    eos

    d = load_asciidoc doc
    expect(d).to_not be_nil

    b = d.find { |bl| bl.context == :image }
    expect(b).to_not be_nil

    expect(b.content_model).to eq :empty

    target = b.attributes['target']
    expect(target).to_not be_nil
    expect(target).to match(/\.svg/)
    expect(File.exist?(target)).to be true

    expect(b.attributes['width']).to_not be_nil
    expect(b.attributes['height']).to_not be_nil
  end
end

describe Asciidoctor::Diagram::AsciiToSvgBlockProcessor, :broken_on_travis, :broken_on_windows do
  it "should generate SVG images when format is set to 'svg'" do
    doc = <<-eos
= Hello, a2s!
Doc Writer <doc@example.com>

== First Section

[a2s, format="svg"]
----
#{code}
----
    eos

    d = load_asciidoc doc
    expect(d).to_not be_nil

    b = d.find { |bl| bl.context == :image }
    expect(b).to_not be_nil

    expect(b.content_model).to eq :empty

    target = b.attributes['target']
    expect(target).to_not be_nil
    expect(target).to match(/\.svg/)
    expect(File.exist?(target)).to be true

    expect(b.attributes['width']).to_not be_nil
    expect(b.attributes['height']).to_not be_nil
  end

  it "should raise an error when when format is set to an invalid value" do
    doc = <<-eos
= Hello, a2s!
Doc Writer <doc@example.com>

== First Section

[a2s, format="foobar"]
----
----
    eos

    expect { load_asciidoc doc }.to raise_error(/support.*format/i)
  end

  it "should not regenerate images when source has not changed" do
    File.write('a2s.txt', code)

    doc = <<-eos
= Hello, a2s!
Doc Writer <doc@example.com>

== First Section

a2s::a2s.txt

[a2s]
----
#{code}
----
    eos

    d = load_asciidoc doc
    b = d.find { |bl| bl.context == :image }
    expect(b).to_not be_nil
    target = b.attributes['target']
    mtime1 = File.mtime(target)

    sleep 1

    d = load_asciidoc doc

    mtime2 = File.mtime(target)

    expect(mtime2).to eq mtime1
  end

  it "should handle two block macros with the same source" do
    File.write('a2s.txt', code)

    doc = <<-eos
= Hello, a2s!
Doc Writer <doc@example.com>

== First Section

a2s::a2s.txt[]
a2s::a2s.txt[]
    eos

    load_asciidoc doc
    expect(File.exist?('a2s.svg')).to be true
  end

  it "should respect target attribute in block macros" do
    File.write('a2s.txt', code)

    doc = <<-eos
= Hello, a2s!
Doc Writer <doc@example.com>

== First Section

a2s::a2s.txt["foobar"]
a2s::a2s.txt["foobaz"]
    eos

    load_asciidoc doc
    expect(File.exist?('foobar.svg')).to be true
    expect(File.exist?('foobaz.svg')).to be true
    expect(File.exist?('a2s.svg')).to be false
  end
end