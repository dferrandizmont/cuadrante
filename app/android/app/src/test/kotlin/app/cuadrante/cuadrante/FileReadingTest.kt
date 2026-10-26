package app.cuadrante.cuadrante

import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream
import java.util.concurrent.CountDownLatch
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/** A stream whose `read` blocks until it is closed, like a provider that hangs. */
private class StuckStream : InputStream() {
    val closed = CountDownLatch(1)
    val entered = CountDownLatch(1)

    override fun read(): Int = block()

    override fun read(b: ByteArray, off: Int, len: Int): Int = block()

    private fun block(): Int {
        entered.countDown()
        closed.await()
        throw IOException("closed while reading")
    }

    override fun close() {
        closed.countDown()
    }
}

class CappedReadTest {
    @Test
    fun readsEverythingUnderTheCap() {
        val data = ByteArray(200_000) { (it % 251).toByte() }
        assertArrayEquals(data, CappedRead.read(ByteArrayInputStream(data), maxBytes = 300_000))
    }

    @Test
    fun exactlyTheCapIsAllowed() {
        val data = ByteArray(1000)
        assertEquals(1000, CappedRead.read(ByteArrayInputStream(data), maxBytes = 1000, chunkBytes = 64).size)
    }

    @Test
    fun oneByteOverTheCapStopsWithoutReadingTheRest() {
        var served = 0
        val endless = object : InputStream() {
            override fun read(): Int = 0.also { served++ }

            override fun read(b: ByteArray, off: Int, len: Int): Int {
                served += len
                return len
            }
        }
        try {
            CappedRead.read(endless, maxBytes = 1000, chunkBytes = 64)
            fail("should be too large")
        } catch (e: TooLargeException) {
            // Stopped at the first chunk past the cap, not at the end of an endless stream.
            assertTrue("read $served bytes", served <= 1000 + 64)
        }
    }
}

class DeadlineReaderTest {
    private val readers = mutableListOf<DeadlineReader>()

    private fun reader(deadlineMillis: Long) = DeadlineReader(deadlineMillis).also { readers += it }

    @After
    fun tearDown() = readers.forEach { it.shutdown() }

    private fun collect(
        reader: DeadlineReader,
        maxBytes: Int = 1 shl 20,
        open: () -> InputStream?,
    ): LinkedBlockingQueue<ReadOutcome> {
        val outcomes = LinkedBlockingQueue<ReadOutcome>()
        reader.start(open, maxBytes) { outcomes.put(it) }
        return outcomes
    }

    @Test
    fun aNormalFileComesBackWhole() {
        val data = ByteArray(10_000) { it.toByte() }
        val outcome = collect(reader(5_000)) { ByteArrayInputStream(data) }.poll(5, TimeUnit.SECONDS)
        assertArrayEquals(data, (outcome as ReadOutcome.Bytes).bytes)
    }

    @Test
    fun aFileOverTheCapIsTooLarge() {
        val outcome = collect(reader(5_000), maxBytes = 100) { ByteArrayInputStream(ByteArray(500)) }
            .poll(5, TimeUnit.SECONDS)
        assertEquals(ReadOutcome.TooLarge, outcome)
    }

    @Test
    fun aMissingStreamOrAFailingProviderIsUnreadable() {
        assertEquals(
            ReadOutcome.Unreadable,
            collect(reader(5_000)) { null }.poll(5, TimeUnit.SECONDS),
        )
        assertEquals(
            ReadOutcome.Unreadable,
            collect(reader(5_000)) { throw SecurityException("grant gone") }.poll(5, TimeUnit.SECONDS),
        )
    }

    @Test
    fun aStuckReadEndsAsUnreadableAtTheDeadlineAndTheStreamIsClosed() {
        val stuck = StuckStream()
        val started = System.nanoTime()
        val outcomes = collect(reader(200)) { stuck }

        val outcome = outcomes.poll(5, TimeUnit.SECONDS)
        val elapsedMs = (System.nanoTime() - started) / 1_000_000

        assertEquals(ReadOutcome.Unreadable, outcome)
        assertTrue("answered after $elapsedMs ms", elapsedMs in 150..3_000)
        assertTrue("stream closed to unblock the read", stuck.closed.await(2, TimeUnit.SECONDS))
        // Reported once only: the unblocked worker must not answer again.
        assertEquals(null, outcomes.poll(500, TimeUnit.MILLISECONDS))
    }

    @Test
    fun aStuckReadDoesNotBlockTheNextFile() {
        val shared = reader(1_000)
        val stuck = StuckStream()
        val first = collect(shared) { stuck }
        assertTrue("first read is blocked", stuck.entered.await(2, TimeUnit.SECONDS))

        // The next file is read while the first is still stuck (before its deadline).
        val data = byteArrayOf(1, 2, 3)
        val second = collect(shared) { ByteArrayInputStream(data) }
        val outcome = second.poll(500, TimeUnit.MILLISECONDS)
        assertTrue("second read came back at once", outcome is ReadOutcome.Bytes)
        assertArrayEquals(data, (outcome as ReadOutcome.Bytes).bytes)
        assertEquals(null, first.peek())

        assertEquals(ReadOutcome.Unreadable, first.poll(5, TimeUnit.SECONDS))
    }

    @Test
    fun theDeadlineCoversOpeningToo() {
        val gate = CountDownLatch(1)
        val outcome = collect(reader(200)) {
            gate.await()
            ByteArrayInputStream(ByteArray(1))
        }.poll(5, TimeUnit.SECONDS)
        gate.countDown()
        assertEquals(ReadOutcome.Unreadable, outcome)
    }

    @Test
    fun eachReadRunsOnItsOwnThread() {
        val threads = LinkedBlockingQueue<Thread>()
        val shared = reader(5_000)
        val stuck = StuckStream()
        shared.start({ threads.put(Thread.currentThread()); stuck }, 100) { }
        assertTrue(stuck.entered.await(2, TimeUnit.SECONDS))
        shared.start({ threads.put(Thread.currentThread()); ByteArrayInputStream(ByteArray(1)) }, 100) { }
        val a = threads.poll(2, TimeUnit.SECONDS)
        val b = threads.poll(2, TimeUnit.SECONDS)
        assertNotEquals(a, b)
        stuck.close()
    }
}
