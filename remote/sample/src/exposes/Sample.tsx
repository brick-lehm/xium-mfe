import {SampleProps} from "../types/sample.type";
import {Button} from "@mui/material";

/**
 * A sample remote component.
 *
 * @constructor
 */
export function Sample({title}: SampleProps) {
    return (
        <div>
            sample {title} remote
            <Button
                color="primary"
                variant="contained"
            >
                HOT RELOAD TEST BUTTON C
            </Button>
        </div>
    )
}
