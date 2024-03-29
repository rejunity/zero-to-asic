#include <iostream>
#include <cmath>
#include <vector>
#include <cstdlib>

#include <SDL2/SDL.h>

#include "VParallax.h"
#include "verilated.h"

#define WINDOW_WIDTH  640
#define WINDOW_HEIGHT 480

int main(int argc, char **argv) {

	std::vector< uint8_t > framebuffer(WINDOW_WIDTH * WINDOW_HEIGHT * 4, 0);

	Verilated::commandArgs(argc, argv);

	VParallax *top = new VParallax;

	// perform a reset
	top->clk = 0;
	top->eval();
	top->reset = 1;
	top->clk = 1;
	top->eval();
	top->reset = 0;

	SDL_Init(SDL_INIT_VIDEO);

	SDL_Window* window =
	    SDL_CreateWindow(
	        "Framebuffer Verilator",
	        SDL_WINDOWPOS_UNDEFINED,
	        SDL_WINDOWPOS_UNDEFINED,
	        WINDOW_WIDTH,
	        WINDOW_HEIGHT,
	        0
	    );

	SDL_Renderer* renderer =
	    SDL_CreateRenderer(
	        window,
	        -1,
	        SDL_RENDERER_ACCELERATED
	    );

	SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
	SDL_RenderClear(renderer);

	SDL_Event e;

	SDL_Texture* texture =
	    SDL_CreateTexture(
	        renderer,
	        SDL_PIXELFORMAT_ARGB8888,
	        SDL_TEXTUREACCESS_STREAMING,
	        WINDOW_WIDTH,
	        WINDOW_HEIGHT
	    );

	bool quit = false;

	int hnum = 0;
	int vnum = 0;

	while (!quit) {

		while (SDL_PollEvent(&e) == 1) {
			if (e.type == SDL_QUIT) {
				quit = true;
			} else if (e.type == SDL_KEYDOWN) {
				switch (e.key.keysym.sym) {
				case SDLK_q:
					quit = true;
				default:
					break;
				}
			}
		}

		auto keystate = SDL_GetKeyboardState(NULL);

		top->reset = keystate[SDL_SCANCODE_ESCAPE];

		// simulate for 20000 clocks
		for (int i = 0; i < 20000; ++i) {

			top->clk = 0;
			top->eval();
			top->clk = 1;
			top->eval();

			// h and v blank logic
			if ((0 == top->hsync) && (0 == top->vsync)) {
				hnum = -128;
				vnum = -28;
			}

			// active frame
			if ((hnum >= 0) && (hnum < 640) && (vnum >= 0) && (vnum < 480)) {
				framebuffer.at((vnum * WINDOW_WIDTH + hnum) * 4 + 0) = (top->rgb & 0b001) ? 255: 0;//>> 0 << 7;
				framebuffer.at((vnum * WINDOW_WIDTH + hnum) * 4 + 1) = (top->rgb & 0b010) ? 255: 0;//>> 1 << 7;
				framebuffer.at((vnum * WINDOW_WIDTH + hnum) * 4 + 2) = (top->rgb & 0b100) ? 255: 0;//>> 2 << 7;
			}

			// keep track of encountered fields
			hnum++;
			if (hnum >= 640 + 24 + 40) {
				hnum = -128;
				vnum++;
			}

			if (vnum >= 480 + 9 + 3) {
				vnum = -28;
			}
		}

		SDL_UpdateTexture(
		    texture,
		    NULL,
		    framebuffer.data(),
		    WINDOW_WIDTH * 4
		);

		SDL_RenderCopy(
		    renderer,
		    texture,
		    NULL,
		    NULL
		);

		SDL_RenderPresent(renderer);
	}

	top->final();
	delete top;

	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_Quit();

	return EXIT_SUCCESS;
}
