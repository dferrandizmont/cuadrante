package es.cuadrante.app

import org.junit.Assert.assertEquals
import org.junit.Test

class DocumentNameTest {
    @Test
    fun aPlainNameIsKept() {
        assertEquals(
            "turnly-2026-11-10-235907.turnly",
            DocumentName.sanitize("turnly-2026-11-10-235907.turnly"),
        )
    }

    @Test
    fun noFolderGetsThroughInTheSuggestedName() {
        assertEquals("x.cuadrante", DocumentName.sanitize("../../etc/x.cuadrante"))
        assertEquals("x.cuadrante", DocumentName.sanitize("C:\\dir\\x.cuadrante"))
    }

    @Test
    fun anEmptyNameFallsBackToADefault() {
        assertEquals("turnly.turnly", DocumentName.sanitize(""))
        assertEquals("turnly.turnly", DocumentName.sanitize("  "))
        assertEquals("turnly.turnly", DocumentName.sanitize("a/"))
    }

    @Test
    fun theMimeTypeIsTheGenericBinaryOne() {
        assertEquals("application/octet-stream", DocumentSaver.MIME_TYPE)
    }
}
