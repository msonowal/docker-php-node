<?php

namespace Fixture\Tests;

use Fixture\Greeter;
use PHPUnit\Framework\TestCase;

// plain assertions only, so it runs on every PHPUnit major the images ship (11 to 13)
final class GreeterTest extends TestCase
{
    public function testGreetsByName(): void
    {
        $this->assertSame('Hello, Ada!', (new Greeter())->greet('Ada'));
    }

    public function testGreetsWithoutAName(): void
    {
        $this->assertSame('Hello!', (new Greeter())->greet(''));
    }
}
