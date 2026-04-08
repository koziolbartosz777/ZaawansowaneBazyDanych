CREATE XML SCHEMA COLLECTION [SalesLT].[ProductAttributeSchema]
    AS N'<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <xsd:element name="Attributes">
    <xsd:complexType>
      <xsd:complexContent>
        <xsd:restriction base="xsd:anyType">
          <xsd:sequence>
            <xsd:element name="FrameMaterial" type="xsd:string" minOccurs="0" />
            <xsd:element name="ForkType" type="xsd:string" minOccurs="0" />
            <xsd:element name="BrakeMount" type="xsd:string" minOccurs="0" />
            <xsd:element name="WheelSize" type="xsd:string" minOccurs="0" />
            <xsd:element name="MaxTireWidth" type="xsd:string" minOccurs="0" />
          </xsd:sequence>
        </xsd:restriction>
      </xsd:complexContent>
    </xsd:complexType>
  </xsd:element>
</xsd:schema>';

