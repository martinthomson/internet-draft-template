---
title: "Roll-Over Counter Assurance for Secure Real-time Transport Protocol (SRTP)"
abbrev: "SRTP Assurance"
category: std
updates: '4568'

docname: draft-davis-valverde-srtp-assurance
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

normative:
  RFC3550: RFC3550
  RFC3711: RFC3711
  RFC3830: RFC3830
  RFC4567: RFC4567
  RFC4568: RFC4568
  RFC4771: RFC4771
  RFC5159: RFC5159
  RFC6904: RFC6904
  RFC8866: RFC8866
  RFC9335: RFC9335

informative:


--- abstract
This document specifies new methods for signaling additional Secure Real-time Transport Protocol (SRTP) cryptographic context information via the Session Description Protcol (SDP)
in alongside those defined by {{RFC4568}}.

The methods defined in this document address situations where the receiver needs to quickly and robustly synchronize. 
The mechanism also enhances SRTP operation in cases where there is a risk of losing sender-receiver synchronization.

--- middle

# Introduction

## Problem Statement {#Problem}

While {{RFC4568}} provides most of the information required to instantiate an SRTP cryptographic context for RTP Packets, 
the state SRTP Rollover Counter (ROC) defined by Section 3.2.1 {{RFC3711}} is not signaled in any packet across the wire and shared between applications.

This value is used as part of the SRTP Packet Index along with the {{RFC3550}} Synchronization sources (SSRC) and Sequence Numberis.
The Packet index is integral to the encrypt/decrypt and authentication process of SRTP keystreams.
Failure to instantiate the value properly leads to encryption or decryption failures, degraded user experience 
and at cross-vendor intoperability issues with many hours of engineering time spent debugging a value that is never negotiated on the wire (and oftentimes not even logged in application logs.)

The current method of ROC handling is to instantiate a new media stream's crypotgrahic context at 0 as per Section 3.3.1 of {{RFC3711}}. 
Then track the state ROC for a given cryptographic context as the time continues on and the stream progresses. 
Where possible the ROC state (and the rest of the cryptographic context) is usually synced across clustered devices or high availability pairs via proprietary methods.

When joining ongoing streams, resuming held/transfered streams, or devices without embedded application logic for clustering/high availability where a given cryptographic context is resumed; 
without any explicit siganling about the ROC state, devices must make an educated guess. Usually this logic is to set the value at 0 as if this is a new stream. 
While technically true from that recievers perspective, the sender of this stream may be encrypting packets with a ROC greater than 0.

There are a few very common scenarios where the ROC may become out of sync which are briefly detailed below with the focus on the ROC Value.

Joining an ongoing session:

{: spacing="compact"}
- When a reciever joines an ongoing session, such as a conference, there is no signaling method which can quickly allow the new participant to know the state of the ROC assuming the state of the stream is shared across all participants.

Hold/Resume, Transfer Scenarios:

{: spacing="compact"}
- A session is created between sender A and reciever B. ROC is instantiated at 0 normally and continues as expected.
- At some point the receiver is put on hold while the sender is connected to some other location such as music on hold or another party altogether.
- At some future point the receiver is reconnected to the sender and the original session is resumed.
- The sender may re-assume the origional cryptographic context rather rather than create one net new. 
- Here if the sender starts the stream from the last observed sequence number the reciever observed the ROC will be in sync.
- However there are scenarios where the sender may have been transmitting packets on the previous cryptographic context and if a ROC increment occured; the reciever would never know. This can lead to problems when the streams are reconnected as the ROC is now out of sync between both parties.
- A similar scenario was brought up in Appendix A of {{RFC4568}} "Scenario B" and "Problem 3" of the Summary within this section.

Application Failover (without stateful syncs):

{: spacing="compact"}
- In this scenario a cryptographic context was was created with Device A and B of a high avialability pair. 
- An SRTP stream was created and ROC of 0 was created and media streamed from the source towards Device A.
- Time continues and the sequence wraps from 65535 to 0 and the ROC is incremented to 1.
- Both the sender and device A are tracking this locally and the encrypt/decrypt process proceeds normally.
- Unfortunate network conditions arise and Device B must assume sessions of Device A transparently.
- Without any proprietary syncing logic between Device A and B which disclose the state of the ROC, Device B will likely instantiate the ROC at 0. 
- Alternativly Device B may try to renegotiate the stream over the desired signaling protocol however this does not ensure the remote sender will change their cryptographic context and reset the ROC to 0.
- The transparent nature of the upstream failover means the local application will likely proceed using ROC 1 while upstream receiver has no method of knowing ROC 1 is the current value.

Improper SRTP context resets:

{: spacing="compact"}
- As defined by Section 3.3.1 of {{RFC3711}} an SRTP re-key MUST NOT reset the ROC within SRTP Cryptographic context.
- However, some applications may incorrectly use the re-key event as a trigger to reset the ROC leading to out-of-sync encrypt/decrypts.

## Previous Solutions {#prevWork}

As per RFC3711, "Receivers joining an on-going session MUST be given the current ROC value using out-of-band signaling such as key-management signaling."
{{RFC4771}} aimed to solve the problem however this solution has a few technnical shortcomings detailed below.

First, this specifies the use of MIKEY defined by {{RFC3830}} as the out-of-band signaling method. 
A proper MIKEY implementation requires more overhead than is needed to convey and solve this problem.
By selecting MIKEY as the out-of-band signaling method the authors may have inadvertently inhibited significant adoption by the industry.

Second, {{RFC4771}} also transforms the SRTP Packet to include the four byte value after the encrypted payload and before an optional auth tag. 
This data about the SRTP context is unencrypted on the wire and not covered by newer SRTP encryption protocols such as {{RFC6904}} and {{RFC9335}}.

Third, this is not in line with RTP Packet modifications and would have benifited greatly from being an RTP Header Extension rather than a value appended after payload. 

Lastly, there is no method for applications defined for applications to advertise the usage of this protocol via any signaling methods.

{{RFC5159}} also defined two attributes namely the "a=SRTPROCTxRate" attribute however this does not cover other important values in the SRTP Cryptographic context and has not seen widespread implementation. 

# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Protocol Design {#design}
This specification adds to what is defined in SDP Security Framework {{RFC4568}} by allowing applications
to explicitly negotiate additional items from the cryptographic context such as the packet index ingredents: ROC, SSRC and Sequence Number via SDP.

By coupling this information with the applicable "a=crypto" offers; a recieving application can properly instantiate 
an SRTP cryptographic context at the start of a session, later in a session, after session modification or when joining an ongoing session.


It should be noted that:

{: spacing="compact"}
- This specifications makes no attempt to be compatiable with the Key Management Extension for SDP "a=key-mgmt" defined by {{RFC4567}}. 
- Is not required by SRTCP since the packet index is carried within the SRTCP packet and does not need an out-of-band equivalent. 

## SDP Considerations {#syntax}
This specification introduces a new SRTP Assurance attribute defined as "a=srtpass".

The presence of the "a=srtpass" attribute in the SDP (in either an offer or an answer) indicates that the endpoint is 
signaling explicit cryptographic context information and this data SHOULD be used in place of derrived values such as those obtained from late binding or some other mechanism.

The SRTP Assurance value syntax is as follows:

~~~
a=srtpass:<a-crypto-tag> index:<ssrc_value_hex>|<roc_value_hex>|<last_known_tx_seq_hex>
~~~

When SSRC, ROC, or Sequence information needs to be conveyed about a given stream, the a=srtpass attribute is coupled with the relevant a=crypto attribute in the SDP.

In {{sampleAttribute}} the sender has shares the usual cryptographic information as per a=crypto but has included 
other information such as the 32 bit SSRC, 32 bit ROC, and 16 bit Last Known Sequence number as Hex values within the a=srtpass attribute.
Together these two attributes provide better insights as to the state of the SRTP cryptographic context from the senders perspective.

~~~~
a=crypto:1 AEAD_AES_256_GCM inline:3/sxOxrbg3CVDrxeaNs91Vle+wW1RvT/zJWTCUNP1i6L45S9qcstjBv+eo0=|2^20|1:32
a=srtpass:1 index:0x00845FED|0x0000|0x0150
~~~~
{: #sampleAttribute title='Example srtp assurance attribute'}

Leading 0s may be ommited and the alphanumeric hex may be upper or lowercase, thus these two lines are functionally identical:
~~~~
a=srtpass:1 index:0x00845FED|0x00000000|0x005D
a=srtpass:1 index:0x845fed|0x0|0x05d
~~~~

The value of "unknown" may be used in place of any of the fields to indicate default behavior 
by the recieving application (usually falling back to late binding or locally derrived/stored cryptogrpahic contaxt information for the packet index.)
The example shown in {{sampleUnknown}} indicates that only the SSRC of the stream is unknown to the sender at the time of the SDP exchange but values for ROC and Last Known Sequence are present. 
This MAY be updated via signaling at any later time but applications SHOULD ensure any offer/answer has the appropriate SRTP assurance attribute.

Applications SHOULD NOT include SRTP Assurane attribute if all three values are unknown. 
For example, starting a new sending session instantiation or for advertising potential cryptographic attributes that are part of a new offer. 
{{sampleUnknown}} shows that tag 1 does not have any SRTP Assurance parameters rather than rather an SRTP Assurance attribute with all three values set to "unknown".

~~~~
a=crypto:1 AES_CM_128_HMAC_SHA1_32 inline:k4x3YXkTD1TWlNL3BZpESzOFuxkBZmTo0vGa1omW
a=crypto:2 AES_CM_128_HMAC_SHA1_80 inline:PS1uQCVeeCFCanVmcjkpPywjNWhcYD0mXXtxaVBR
a=srtpass:2 index:unknown|0x0001|0x3039
~~~~
{: #sampleUnknown title='Example srtp assurance with unknown mappings'}

The tag for an SRTP assurance attribute MUST follow the peer SDP Security a=crypto tag for a given media stream (m=).
The example in shown in {{sampleTag}} the sender is advertising an explicit packet index mapping for a=crypto tag 2 for the audio stream and tag 1 for the video media stream. 
Note that some SDP values have been truncated for the sake of simplicity.

~~~~
c=IN IP4 168.2.17.12
m=audio 49170 RTP/SAVP 0
a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:d0RmdmcmVCspeEc3QGZiNWpVLFJhQX1cfHAwJSoj|2^20|1:32
a=crypto:2 AEAD_AES_256_GCM inline:HGAPy4Cedy/qumbZvpuCZSVT7rNDk8vG4TdUXp5hkyWqJCqiLRGab0KJy1g=
a=srtpass:2 index:0x00845FED|0x0001|0x3039
m=video 49172 RTP/SAVP 126
a=crypto:1 AEAD_AES_128_GCM inline:bQJXGzEPXJPClrd78xwALdaZDs/dLttBLfLE5Q==
a=srtpass:1 index:0xDD147C14|0x0001|0x3039
~~~~
{: #sampleTag title='Example crypto and srtp assurance tag mapping'}

SRTP Assurance is compatiable with {{RFC9335}} "a=cryptex" media and session level attribute.

# Security Considerations

When SDP carries SRTP Assurance attributes additional insights are present about the SRTP Cryptographic context.
Care MUST be taken as per the {{RFC8866}} that keying material must not be sent over unsecure channels unless the SDP can be both private (encrypted) and authenticated.

# IANA Considerations

This document updates the "attribute-name (formerly "att-field")" subregistry of the "Session Description Protocol (SDP) Parameters" registry (see Section 8.2.4 of [RFC8866]). 
Specifically, it adds the SDP "a=srtpass" attribute for use at both the media level.

~~~~
Contact name: IETF AVT Working Group or IESG if the AVT Working Group is closed
Contact email address: avt@ietf.org
Attribute name: srtpass
Attribute syntax: TODO
Attribute semantics: TODO
Attribute value: TODO
Usage level: media
Charset dependent: No
Purpose: Provide additional insights about SRTP context information not conveyed required by a recever to properly decrypt SRTP.
O/A procedures: SDP O/A procedures are described in {{syntax}} of this document.
Mux Category: TRANSPORT
~~~~

--- back