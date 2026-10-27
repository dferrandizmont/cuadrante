package es.cuadrante.app

import org.junit.Assert.assertEquals
import org.junit.Test

class DocumentNameTest {
    @Test
    fun aPlainNameIsKept() {
        assertEquals(
            "cuadrante-2026-11-10-235907.cuadrante",
            DocumentName.sanitize("cuadrante-2026-11-10-235907.cuadrante"),
        )
    }

    @Test
    fun noFolderGetsThroughInTheSuggestedName() {
        assertEquals("x.cuadrante", DocumentName.sanitize("../../etc/x.cuadrante"))
        assertEquals("x.cuadrante", DocumentName.sanitize("C:\\dir\\x.cuadrante"))
    }

    @Test
    fun anEmptyNameFallsBackToADefault() {
        assertEquals("cuadrante.cuadrante", DocumentName.sanitize(""))
        assertEquals("cuadrante.cuadrante", DocumentName.sanitize("  "))
        assertEquals("cuadrante.cuadrante", DocumentName.sanitize("a/"))
    }

    @Test
    fun theMimeTypeIsTheGenericBinaryOne() {
        assertEquals("application/octet-stream", DocumentSaver.MIME_TYPE)
    }
}
