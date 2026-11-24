"""Render the per-user PipeWire filter-chain fragment."""
import argparse
import json


def config(rnnoise, compressor):
    controls = {
        "Attack threshold (G)": 10 ** (-18 / 20),
        "Attack time (ms)": 15.0,
        "Release time (ms)": 180.0,
        "Ratio": 2.0,
        "Knee (G)": 10 ** (-4 / 20),
        "Makeup gain (G)": 1.0,
    }
    label = "http://lsp-plug.in/plugins/ladspa/compressor_stereo"
    ins = ["Input L", "Input R"]
    outs = ["Output L", "Output R"]

    capture = {"node.name": "capture.honor-dmic-rnnoise-voice", "node.passive": True,
               "target.object": "honor-dmic", "node.dont-move": True,
               "node.dont-fallback": True}
    description = "Built-in Microphone (RNNoise)"
    graph = {
        "nodes": [
            *[{"type": "builtin", "name": f"lowcut_{ch}", "label": "bq_highpass",
               "control": {"Freq": 75.0, "Q": 0.707}} for ch in "LR"],
            {"type": "ladspa", "name": "rnnoise", "plugin": rnnoise,
             "label": "noise_suppressor_stereo", "control": {"VAD Threshold (%)": 0.0}},
            {"type": "ladspa", "name": "comp", "plugin": compressor, "label": label,
             "control": controls},
        ],
        "links": [
            *[{"output": f"lowcut_{ch}:Out", "input": f"rnnoise:Input ({ch})"} for ch in "LR"],
            *[{"output": f"rnnoise:Output ({ch})", "input": f"comp:{port}"}
              for ch, port in zip("LR", ins)],
        ],
        "inputs": ["lowcut_L:In", "lowcut_R:In"],
        "outputs": [f"comp:{port}" for port in outs],
    }
    return {"context.modules": [{
        "name": "libpipewire-module-filter-chain",
        "flags": ["nofail"],
        "args": {"node.description": description, "media.name": description,
                 "audio.rate": 48000, "audio.channels": 2, "audio.position": ["FL", "FR"],
                 "filter.graph": graph, "capture.props": capture,
                 "playback.props": {"node.name": "honor-dmic-rnnoise-voice",
                                    "node.description": description,
                                    "media.class": "Audio/Source", "priority.session": 1}},
    }]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rnnoise")
    parser.add_argument("compressor")
    print(json.dumps(config(**vars(parser.parse_args())), indent=2))
