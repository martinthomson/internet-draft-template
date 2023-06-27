---
title: "SDP Security Assurance for Secure Real-time Transport Protocol (SRTP)"
abbrev: "SRTP Assurance"
category: std
updates: '4568'

docname: draft-davis-valverde-srtp-assurance-00
submissiontype: IETF
date: 2023
consensus: true
v: 3
area: ART

author:
- name: Kyzer R. Davis
  email: kydavis@cisco.com
  org: Cisco Systems
- name: Esteban Valverde
  email: jovalver@cisco.com
  org: Cisco Systems
- name: Gonzalo Salgueiro
  email: gsalguei@cisco.com
  org: Cisco Systems

normative:
  RFC3711: RFC3711
  RFC4568: RFC4568
  RFC8859: RFC8859
  RFC8866: RFC8866

informative:
  RFC3550: RFC3550
  RFC3830: RFC3830
  RFC4567: RFC4567
  RFC4771: RFC4771
  RFC5159: RFC5159
  RFC5234: RFC5234
  RFC5479: RFC5479
  RFC5576: RFC5576
  RFC5763: RFC5763
  RFC5764: RFC5764
  RFC6184: RFC6184
  RFC6189: RFC6189
  RFC6904: RFC6904
  RFC7201: RFC7201
  RFC7714: RFC7714
  RFC8723: RFC8723
  RFC8792: RFC8792
  RFC8870: RFC8870
  RFC8871: RFC8871
  RFC8872: RFC8872
  RFC9335: RFC9335

--- abstract
This document specifies additional cryptographic attributes for signaling additional Secure Real-time Transport Protocol (SRTP) cryptographic context information via the Session Description Protocol (SDP)
in alongside those defined by RFC4568.

The SDP extension defined in this document address situations where the receiver needs to quickly and robustly synchronize with a given sender.
The mechanism also enhances SRTP operation in cases where there is a risk of losing sender-receiver synchronization.

--- middle

# Introduction

## Problem Statement {#Problem}

While {{RFC4568}} provides most of the information required to instantiate an SRTP cryptographic context for RTP Packets, 
the state of a few crucial items in the SRTP cryptographic context are missing.
One such item is the Rollover Counter (ROC) defined by Section 3.2.1 {{RFC3711}}
which is not signaled in any packet across the wire and shared between applications.

The ROC is one item that is used to create the SRTP Packet Index along with the the {{RFC3550}} transmitted sequence numbers for a given synchronization sources (SSRC).
The Packet index is integral to the encryption, decryption and authentication process of SRTP key streams.
Failure to synchronize the value properly at any point in the SRTP media exchange leads to encryption or decryption failures, degraded user experience 
and at cross-vendor interoperability issues with many hours of engineering time spent debugging a value that is never negotiated on the wire 
(and oftentimes not even logged in application logs.)

The current method of ROC handling is to instantiate a new media stream's cryptographic context at 0 as per Section 3.3.1 of {{RFC3711}}. 
Then track the state ROC for a given cryptographic context as the time continues on and the stream progresses. 


When joining ongoing streams, resuming held/transferred streams, or devices without embedded application logic for clustering/high availability where a given cryptographic context is resumed; 
without any explicit signaling about the ROC state, devices must make an educated guess as defined by Section 3.3.1 of {{RFC3711}}.
The method specially estimates the received ROC by calculating ROC-1, ROC, ROC+1 to see which performs a successful decrypt.
While this may work on paper, this process usually only done at the initial instantiation of a cryptographic context rather than at later points later during the session.
Instead many applications take the easy route and set the value at 0 as if this is a new stream.
While technically true from that receivers perspective, the sender of this stream may be encrypting packets with a ROC greater than 0.
Further this does not cover scenarios where the ROC is greater than +1.

Where possible the ROC state (and the rest of the cryptographic context) is usually synced across clustered devices or high availability pairs via proprietary methods rather than open standards.

These problems detailed technically above lead to a few very common scenarios where the ROC may become out of sync. 
These are are briefly detailed below with the focus on the ROC Value.

Joining an ongoing session:

{: spacing="compact"}
- When a receiver joins an ongoing session, such as a broadcast conference, there is no signaling method which can quickly allow the new participant to know the state of the ROC assuming the state of the stream is shared across all participants.


Hold/Resume, Transfer Scenarios:

{: spacing="compact"}
- A session is created between sender A and receiver B. ROC is instantiated at 0 normally and continues as expected.
- At some point the receiver is put on hold while the sender is connected to some other location such as music on hold or another party altogether.
- At some future point the receiver is reconnected to the sender and the original session is resumed.
- The sender may re-assume the original cryptographic context rather rather than create one net new. 
- Here if the sender starts the stream from the last observed sequence number the receiver observed the ROC will be in sync.
- However there are scenarios where the sender may have been transmitting packets on the previous cryptographic context and if a ROC increment occurred; the receiver would never know. This can lead to problems when the streams are reconnected as the ROC is now out of sync between both parties.
- A similar scenario was brought up in Appendix A of {{RFC4568}} "Scenario B" and "Problem 3" of the summary within this section.
- Further, a sender may be transferred to some upstream device transparently to them. If the sender does not reset their cryptographic context that new receiver will now be out of sync with possible ROC values.

Application Failover (without stateful syncs):

{: spacing="compact"}
- In this scenario a cryptographic context was was created with Device A and B of a high availability pair. 
- An SRTP stream was created and ROC of 0 was created and media streamed from the source towards Device A.
- Time continues and the sequence wraps from 65535 to 0 and the ROC is incremented to 1.
- Both the sender and device A are tracking this locally and the encrypt/decrypt process proceeds normally.
- Unfortunate network conditions arise and Device B must assume sessions of Device A transparently.
- Without any proprietary syncing logic between Device A and B which disclose the state of the ROC, Device B will likely instantiate the ROC at 0. 
- Alternatively Device B may try to renegotiate the stream over the desired signaling protocol however this does not ensure the remote sender will change their cryptographic context and reset the ROC to 0.
- The transparent nature of the upstream failover means the local application will likely proceed using ROC 1 while upstream receiver has no method of knowing ROC 1 is the current value.

Secure SIPREC Recording:

{: spacing="compact"}
- If a SIPREC recorder is brought into recording an ongoing session through some form of transfer or on-demand recording solution the ROC may have incremented.
- Without an SDP mechanism to share this information the SIPREC will be unaware of the full SRTP context required to ensure proper decrypt of media streams being monitored.

Improper SRTP context resets:

{: spacing="compact"}
- As defined by Section 3.3.1 of {{RFC3711}} an SRTP re-key MUST NOT reset the ROC within SRTP Cryptographic context.
- However, some applications may incorrectly use the re-key event as a trigger to reset the ROC leading to out-of-sync encrypt/decrypt operations.

This is a problem that other SRTP Key Management protocols (MIKEY, DTLS-SRTP, EKT-SRTP) have solved but SDP Security has lagged behind in solution parity. 
For a quick comparison of all SRTP Key Management negotiations refer to {{RFC7201}} and {{RFC5479}}.

## Previous Solutions {#prevWork}

As per RFC3711, "Receivers joining an on-going session MUST be given the current ROC value using out-of-band signaling such as key-management signaling."
{{RFC4771}} aimed to solve the problem however this solution has a few technical shortcomings detailed below.

First, this specifies the use of Multimedia Internet KEYing (MIKEY) defined by {{RFC3830}} as the out-of-band signaling method. 
A proper MIKEY implementation requires more overhead than is needed to convey and solve this problem.
By selecting MIKEY as the out-of-band signaling method the authors may have inadvertently inhibited significant adoption by the industry.

Second, {{RFC4771}} also transforms the SRTP Packet to include the four byte value after the encrypted payload and before an optional authentication tag. 
This data about the SRTP context is unencrypted on the wire and not covered by newer SRTP encryption protocols such as {{RFC6904}} and {{RFC9335}}.
Furthermore this makes the approach incompatible with AEAD SRTP Cipher Suites which state that trimming/truncating the authentication tag weakens the security of the protocol in Section 13.2 of {{RFC7714}}.


Third, this is not in line with the standard method of RTP Packet modifications. 
The proposal would have benefited greatly from being an RTP Header Extension rather than a value appended after payload. 
But even an RTP header extension proves problematic in where modern SRTP encryption such as Cryptex defined by {{RFC9335}} are applied. 
That is, the ROC is a required input to decrypt the RTP packet contents. It does not make sense to convey this data as an RTP Header Extension 
obfuscated by the very encryption it is required to decrypt.

Lastly, there is no defined method for applications defined for applications to advertise the usage of this protocol via any signaling methods.

{{RFC5159}} also defined some SDP attributes namely the "a=SRTPROCTxRate" attribute however this does not cover other important values in the SRTP Cryptographic context and has not seen widespread implementation. 

{{RFC8870}} solves the problem for DTLS-SRTP {{RFC5763}/{{RFC5764}} implementations.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Protocol Design {#design}
A few points of note are below about this specifications relationship to other SRTP Key Management protocols or SRTP protocols as to leave no ambiguity.

{: vspace='0'}
Session Description Protocol (SDP) Security Descriptions for Media Streams:
: The authors have chosen to avoid modifying RFC4568 a=crypto offers as to avoid backwards compatibility issues with a non-versioned protocol. 
  Instead this specification adds to what is defined in SDP Security Framework {{RFC4568}} by allowing applications
  to explicitly negotiate additional items from the cryptographic context such as the packet index ingredients: ROC, SSRC and Sequence Number via a new SDP Attribute.
  By coupling this information with the applicable "a=crypto" offers; a receiving application can properly instantiate 
  an SRTP cryptographic context at the start of a session, later in a session, after session modification or when joining an ongoing session.

Key Management Extensions for Session Description Protocol (SDP) and Real Time Streaming Protocol (RTSP):
: This specifications makes no attempt to be compatible with the Key Management Extension for SDP "a=key-mgmt" defined by {{RFC4567}}

ZRTP: Media Path Key Agreement for Unicast Secure RTP:
: This specifications makes no attempt to be compatible with the Key Management via SDP for ZRTP "a=zrtp-hash" defined by {{RFC6189}}. 

DTLS-SRTP, EKT-SRTP, Privacy Enhanced Conferencing items (PERC):
: All DTLS-SRTP items including Privacy Enhanced Conferencing items (PERC) [ {{RFC8723}} and {{RFC8871}} ] are out of scope for the purposes of this specification.

Secure Real Time Control Protocol (SRTCP):
: This specification is  not required by SRTCP since the packet index is carried within the SRTCP packet and does not need an out-of-band equivalent.

Source-Specific Media Attributes in the Session Description Protocol (SDP):
: The authors of this specification vetted {{RFC5576}} SSRC Attribute "a=ssrc" but felt that it would require too much modification and additions to the SSRC Attribute
  specification to allow unknown SSRC values and the other information which needs to be conveyed.
  Further, requiring implementation of the core SSRC Attribute RFC could pose as a barrier entry and separating the two into different SDP Attributes is the better option.
  An implementation SHOULD NOT send RFC5576 SSRC Attributes alongside SRTP Context SSRC Attributes. 
  If both are present in SDP, a receiver SHOULD utilize prioritize the SRTP Context attributes over SSRC Attributes since these attributes will provide better SRTP cryptographic context initialization. 

Completely Encrypting RTP Header Extensions and Contributing Sources:
: SRTP Context is compatible with {{RFC9335}} "a=cryptex" media and session level attribute.

## SDP Considerations {#syntax}
This specification introduces a new SRTP Context attribute defined as "a=srtpctx".

The presence of the "a=srtpctx" attribute in the SDP (in either an offer or an answer) indicates that the endpoint is 
signaling explicit cryptographic context information and this data SHOULD be used in place of derived values such as those obtained from late binding or some other mechanism.

The SRTP Context value syntax utilizes standard attribute field=value pairs separated by semi-colons as seen in {{sampleBase}}.
The implementation's goal is extendable allowing for additional vendor specific field=value pairs alongside the ones defined in this document or room for future specifications to add additional field=value pairs.

~~~
a=srtpctx:<a-crypto-tag> \
  <att_field_1>=<value_1>;<att_field_1>=<att_value_2>
~~~
{: #sampleBase title='Base SRTP Context Syntax'}

This specification specifically defines SRTP Context Attribute Fields of SSRC, ROC, and SEQ shown in {{sampleSyntax}}.

~~~
a=srtpctx:<a-crypto-tag> \
  ssrc=<ssrc_value_hex>;roc=<roc_value_hex>;seq=<last_known_tx_seq_hex>
~~~
{: #sampleSyntax title='Example SRTP Context Syntax'}
Note that long lines in this document have been broken into multiple lines using the "The Single Backslash Strategy ('\')" defined by {{RFC8792}}.

The formal definition of the SRTP Context Attribute, including custom extension field=value pairs is provided by the following ABNF {{RFC5234}}:

~~~~ abnf
srtp-assurance = srtp-attr
                 srtp-tag
                 [srtp-ssrc";"]
                 [srtp-roc";"]
                 [srtp-seq";"]
                 [srtp-ext";"]
srtp-attr      = "a=srtpctx:"
srtp-tag       = 1*9DIGIT 1WSP 
srtp-ssrc      = "ssrc=" ("0x"1*8HEXDIG / "unknown")
srtp-roc       = "roc=" ("0x"1*4HEXDIG / "unknown")
srtp-seq       = "seq=" ("0x"1*4HEXDIG / "unknown")
srtp-ext       = 1*VCHAR "=" (1*VCHAR / "unknown")
ALPHA          = %x41-5A / %x61-7A   ; A-Z / a-z
DIGIT          = %x30-39
HEXDIG         = DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
VCHAR          = %x21-7E
~~~~

Leading 0s may be omitted and the alphanumeric hex may be upper or lowercase but at least one 0 must be present. 
Additionally the "0x" provided additional context that these values are hex and not integers.
Thus as per {{sampleCompare}} these two lines are functionally identical:

~~~~
a=srtpctx:1 ssrc=0x00845FED;roc=0x00000000;seq=0x005D
a=srtpctx:1 ssrc=0x845fed;roc=0x0;seq=0x05d
~~~~
{: #sampleCompare title='Comparison with and without Leading 0s'}

When SSRC, ROC, or Sequence information needs to be conveyed about a given stream, the a=srtpctx attribute is coupled with the relevant a=crypto attribute in the SDP.

In {{sampleAttribute}} the sender has shares the usual cryptographic information as per a=crypto but has included 
other information such as the 32 bit SSRC, 32 bit ROC, and 16 bit Last Known Sequence number as Hex values within the a=srtpctx attribute.
Together these two attributes provide better insights as to the state of the SRTP cryptographic context from the senders perspective.

~~~~
a=crypto:1 AEAD_AES_256_GCM \
  inline:3/sxOxrbg3CVDrxeaNs91Vle+wW1RvT/zJWTCUNP1i6L45S9qcstjBv+eo0=\
  |2^20|1:32
a=srtpctx:1 ssrc=0x00845FED;roc=0x0000;seq=0x0150
~~~~
{: #sampleAttribute title='Example SRTP Context attribute'}

The value of "unknown" MAY be used in place of any of the fields to indicate default behavior SHOULD be utilized
by the receiving application (usually falling back to late binding or locally derived/stored cryptographic contact information for the packet index.)
The example shown in {{sampleUnknown}} indicates that only the SSRC of the stream is unknown to the sender at the time of the SDP exchange but 
values for ROC and Last Known Sequence are present. Alternatively, the attribute key and value MAY be omitted entirely.

This MAY be updated via signaling at any later time but applications SHOULD ensure any offer/answer has the appropriate SRTP Context attribute.

Applications SHOULD NOT include SRTP Context attribute if all three values are unknown or would be omitted.
For example, starting a new sending session instantiation or for advertising potential cryptographic attributes that are part of a new offer. 

{{sampleUnknown}} shows that tag 1 does not have any SRTP Context parameters rather than rather an SRTP Context attribute with all three values set to "unknown".
This same example shows an unknown value carried with tag 2 and seq has been committed leaving only the ROC as a value shared with the second a=crypto tag.

~~~~
a=crypto:1 AES_CM_128_HMAC_SHA1_32 \
  inline:k4x3YXkTD1TWlNL3BZpESzOFuxkBZmTo0vGa1omW
a=crypto:2 AES_CM_128_HMAC_SHA1_80 \
  inline:PS1uQCVeeCFCanVmcjkpPywjNWhcYD0mXXtxaVBR
a=srtpctx:2 ssrc=unknown;roc=0x0001
~~~~
{: #sampleUnknown title='Example SRTP Context with unknown mappings'}

The tag for an SRTP Context attribute MUST follow the peer SDP Security a=crypto tag for a given media stream (m=).
The example in shown in {{sampleTag}} the sender is advertising an explicit packet index mapping for a=crypto tag 2 for the audio stream and tag 1 for the video media stream. 
Note that some SDP values have been truncated for the sake of simplicity.

~~~~
c=IN IP4 192.0.0.1
m=audio 49170 RTP/SAVP 0
a=crypto:1 AES_CM_128_HMAC_SHA1_80 \
  inline:d0RmdmcmVCspeEc3QGZiNWpVLFJhQX1cfHAwJSoj|2^20|1:32
a=crypto:2 AEAD_AES_256_GCM \
  inline:HGAPy4Cedy/qumbZvpuCZSVT7rNDk8vG4TdUXp5hkyWqJCqiLRGab0KJy1g=
a=srtpctx:2 ssrc=0xBFBDD;roc=0x0001;seq=0x3039
m=video 49172 RTP/SAVP 126
a=crypto:1 AEAD_AES_128_GCM \
  inline:bQJXGzEPXJPClrd78xwALdaZDs/dLttBLfLE5Q==
a=srtpctx:1 ssrc=0xDD147C14;roc=0x0001;seq=0x3039
~~~~
{: #sampleTag title='Example crypto and SRTP Context tag mapping'}

It is unlikely a sender will send SRTP Context attributes for every crypto attribute since many will be fully unknown (such as the start of a session.)
However it is theoretically possible for every a=crypto tag to have a similar a=srtpctx attribute for additional details. 

For scenarios where RTP Multiplexing are concerned, EKT-SRTP ({{RFC8870}}) MUST be used in lieu of SDP Security as per {{RFC8872}} Section 4.3.2.

For scenarios where SDP Bundling are concerned, SRTP Context attributes follow the same bundling guidelines defined by {{RFC8859}}, section 5.7 for SDP Securities a=crypto attribute.

## Sender Behavior {#sender}
Senders utilizing SDP Security via "a=crypto" MUST make an attempt to signal any known packet index values to the peer receiver.
The exception being when all values are unknown, such as at the very start of medias stream negotiation.

For best results all sending parties of a given session stream SHOULD advertise known packet index values for all media streams.
This should continue throughout the life of the session to ensure any errors or out of sync errors can be quickly corrected via new signaling methods. 
See {{frequency}} for update frequency recommendations.

## Receiver Behavior {#receiver}
Receivers SHOULD utilize the signaled information in application logic to instantiate the SRTP cryptographic context.
In the even there is no SRTP Context attributes present in SDP receivers MUST fallback to {{RFC3711}} for guesting 
the ROC and {{RFC4568}} logic for late binding to gleam the SSRC and sequence numbers.

## Update Frequency {#frequency}
Senders SHOULD provide SRTP Context SDP when SDP Crypto attributes are negotiated.
There is no explicit time or total number of packets in which a new update is required from sender to receiver.
By following natural session updates,  session changes and session liveliness checks this specification will not cause 
overcrowding on the session establishment protocol's signaling channel.

## Extendability {#extendability}
As stated in {{syntax}}, the SRTP Context SDP implementation's goal is extendability allowing for additional vendor specific field=value pairs alongside the ones defined in this document.
This ensures that a=crypto SDP security may remain compatible with future algorithms that need to signal cryptographic context information outside of what is currently specified in {{RFC4568}}.

To illustrate, imagine a new example SRTP algorithm and crypto suite is created named "FOO_CHACHA20_POLY1305_SHA256" and the application needs to signal "Foo, "Bar", and "Nonce" values to properly instantiate the SRTP context.
Rather than modify a=crypto SDP security or create a new unique SDP attribute, one can simply utilize SRTP Context SDP's key=value pairs to convey the information.

~~~~
a=crypto:1 FOO_CHACHA20_POLY1305_SHA256 \
  inline:1ef9a49f1f68f75f95feca6898921db8c73bfa53e71e33726c4c983069dd7d44
a=srtpctx:1 foo=1;bar=abc123;nonce=8675309
~~~~

With this extendable method, all that is now required in the fictional RFC defining "FOO_CHACHA20_POLY1305_SHA256" is to include an "SDP parameters" section which details the expected "a=srtpctx" values and their usages.
This approach is similar to how Media Format Parameter Capability ("a=fmtp") is utilized in modern SDP. An example is {{RFC6184}}, Section 8.2.1 for H.264 video Media Format Parameters.

# Security Considerations
When SDP carries SRTP Context attributes additional insights are present about the SRTP cryptographic context.
Due to this an intermediary MAY be able to analyze how long a session has been active by the ROC value.

Since the SRTP Context attribute is carried in plain-text (alongside existing values like the SRTP Master Key for a given session)
care MUST be taken as per the {{RFC8866}} that keying material must not be sent over unsecure channels unless the SDP can be both private (encrypted) and authenticated.

# IANA Considerations

This document updates the "attribute-name (formerly "att-field")" sub-registry of the "Session Description Protocol (SDP) Parameters" registry (see Section 8.2.4 of [RFC8866]). 
Specifically, it adds the SDP "a=srtpctx" attribute for use at the media level.

| Form                  | Value |
| Contact name          | IESG |
| Contact email address | kydavis@cisco.com |
| Attribute name        | srtpctx |
| Attribute value       | srtpctx |
| Attribute syntax      | Provided by ABNF found in {{syntax}} |
| Attribute semantics   | Provided by sub-sections of {{design}} |
| Usage level           | media |
| Charset dependent     | No |
| Purpose               | Provide additional insights about SRTP context information not conveyed required by a receiver to properly decrypt SRTP. |
| O/A procedures        | SDP O/A procedures are described in {{syntax}}, specifically sections {{sender}} and {{receiver}} of this document. |
| Mux Category          | TRANSPORT |
{: #ianaForm title='IANA SDP Registration Form'}

# Acknowledgements
Thanks to Paul Jones for reviewing early draft material and providing valueable feedback.

--- back